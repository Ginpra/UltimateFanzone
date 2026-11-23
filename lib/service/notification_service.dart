import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notifikasi lokal (Modul VII): langsung (immediate) dan terjadwal.
///
/// Dibuat sebagai singleton supaya seluruh aplikasi memakai satu plugin.
/// `init()` dipanggil sekali di `main()`.
///
/// Catatan versi: paket `flutter_local_notifications` versi baru (22 ke atas)
/// memakai parameter BERNAMA (`id:`, `title:`, ...), beda dengan contoh modul
/// yang memakai parameter posisi. Di `pubspec.yaml` versinya dikunci ke 22.3.3
/// karena versi 23 menuntut compileSdk 37.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'reminder_channel';
  static const _channelName = 'Reminder Notifications';

  Future<void> init() async {
    // 1. Zona waktu (dipakai notifikasi terjadwal)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // 2. Konfigurasi Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // 3. Izin notifikasi dan channel
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Channel untuk pengingat dan SOS',
        importance: Importance.high,
      ),
    );
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// Immediate notification: muncul langsung saat dipanggil.
  Future<void> showInstantNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  /// Scheduled notification: muncul pada [scheduledTime] (jam lokal).
  ///
  /// Android 12 ke atas bisa menolak alarm tepat waktu. Bila ditolak, dicoba
  /// lagi dengan alarm tidak-tepat (bisa terlambat beberapa menit).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final when = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
