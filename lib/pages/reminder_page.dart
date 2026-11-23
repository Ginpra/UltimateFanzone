import 'package:flutter/material.dart';

import '../core/format.dart';
import '../model/football_match.dart';
import '../service/football_service.dart';
import '../service/notification_service.dart';
import '../service/settings_service.dart';
import '../widgets/error_state.dart';

/// Pengingat laga: nyalakan lonceng pada laga mendatang, notifikasi muncul
/// beberapa menit sebelum kickoff.
///
/// Modul: VII (notifikasi instan dan terjadwal), V (data laga), VI (SharedPreferences).
class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final _football = FootballService();
  final _settings = SettingsService();
  final _notifications = NotificationService();

  bool _loading = true;
  String? _error;
  List<FootballMatch> _upcoming = [];
  List<int> _reminderIds = [];
  int _minutes = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _football.getMatches();
      final ids = await _settings.loadReminderIds();
      final minutes = await _settings.loadReminderMinutes();
      final now = DateTime.now().toUtc();
      final upcoming =
          data.items
              .where((m) => !m.isFinished && m.kickoffUtc.isAfter(now))
              .toList()
            ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));
      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _reminderIds = ids;
        _minutes = minutes;
        _loading = false;
      });
    } on FootballException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(FootballMatch match) async {
    final active = _reminderIds.contains(match.id);
    if (active) {
      await _notifications.cancel(match.id);
      _reminderIds.remove(match.id);
      await _settings.saveReminderIds(_reminderIds);
      if (!mounted) return;
      setState(() {});
      _snack('Pengingat dimatikan.');
      return;
    }

    final remindAt = match.kickoffUtc.toLocal().subtract(
      Duration(minutes: _minutes),
    );
    if (!remindAt.isAfter(DateTime.now())) {
      _snack('Waktu pengingat sudah lewat. Pilih menit yang lebih kecil.');
      return;
    }
    await _notifications.scheduleNotification(
      id: match.id,
      title: 'Sebentar lagi kickoff!',
      body: '${match.label} mulai $_minutes menit lagi.',
      scheduledTime: remindAt,
    );
    _reminderIds.add(match.id);
    await _settings.saveReminderIds(_reminderIds);
    if (!mounted) return;
    setState(() {});
    _snack('Pengingat dipasang untuk ${formatDateTime(remindAt)}.');
  }

  Future<void> _changeMinutes(int minutes) async {
    await _settings.saveReminderMinutes(minutes);
    setState(() => _minutes = minutes);
  }

  Future<void> _testNow() async {
    await _notifications.showInstantNotification(
      title: 'Tes notifikasi',
      body: 'Notifikasi langsung berhasil muncul.',
    );
  }

  Future<void> _testIn1Minute() async {
    await _notifications.scheduleNotification(
      id: 999999,
      title: 'Tes pengingat',
      body: 'Notifikasi terjadwal berhasil muncul.',
      scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
    );
    if (!mounted) return;
    _snack(
      'Pengingat tes dijadwalkan 1 menit lagi. Tutup aplikasi untuk mencoba.',
    );
  }

  Widget _settingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingatkan sebelum kickoff'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [15, 30, 60])
                  ChoiceChip(
                    label: Text('$m menit'),
                    selected: _minutes == m,
                    onSelected: (_) => _changeMinutes(m),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilihan ini berlaku untuk pengingat yang dipasang berikutnya.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _testNow,
                  child: const Text('Tes sekarang'),
                ),
                OutlinedButton(
                  onPressed: _testIn1Minute,
                  child: const Text('Tes 1 menit lagi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _settingsCard(),
        if (_upcoming.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Tidak ada laga mendatang.')),
          ),
        for (final m in _upcoming)
          Card(
            child: ListTile(
              title: Text(m.label),
              subtitle: Text(formatDateTime(m.kickoffUtc)),
              trailing: IconButton(
                tooltip: 'Pengingat',
                icon: Icon(
                  _reminderIds.contains(m.id)
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                ),
                onPressed: () => _toggle(m),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Laga')),
      body: _body(),
    );
  }
}
