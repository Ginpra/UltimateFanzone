import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../service/location_service.dart';
import '../service/notification_service.dart';

/// SOS: tahan tombol merah untuk mengambil lokasi. Lokasi tampil di layar dan lewat
/// notifikasi di HP ini; **tidak dikirim ke siapa pun**. Modul: VII.
class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> {
  final _location = LocationService();
  final _notifications = NotificationService();

  bool _busy = false;
  String? _coordinates;
  DateTime? _time;

  Future<void> _trigger() async {
    setState(() => _busy = true);
    try {
      final pos = await _location.getCurrentPosition();
      final text =
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      await _notifications.showInstantNotification(
        id: 1,
        title: 'SOS: lokasi saya',
        body: 'Koordinat: $text',
      );
      if (!mounted) return;
      setState(() {
        _coordinates = text;
        _time = DateTime.now();
        _busy = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _coordinates!));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Koordinat disalin.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Darurat')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Tahan tombol di bawah sekitar 1 detik untuk mengambil lokasimu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onLongPress: _busy ? null : _trigger,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: scheme.error,
                child: _busy
                    ? CircularProgressIndicator(color: scheme.onError)
                    : Text(
                        'SOS',
                        style: TextStyle(
                          color: scheme.onError,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            if (_coordinates != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Lokasi pada ${formatDateTime(_time!)}'),
                      const SizedBox(height: 8),
                      Text(
                        _coordinates!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy),
                        label: const Text('Salin koordinat'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum dikirim ke siapa pun. Salin lalu kirim sendiri.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
