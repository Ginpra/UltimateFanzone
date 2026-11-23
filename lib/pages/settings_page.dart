import 'package:flutter/material.dart';

import '../model/app_settings.dart';
import '../service/settings_service.dart';

/// Pengaturan suporter (SharedPreferences, Modul VI).
///
/// Mengembalikan `true` lewat `Navigator.pop` bila disimpan, supaya layar
/// sebelumnya memuat ulang datanya (Modul IV).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _service = SettingsService();
  final _nicknameController = TextEditingController();
  bool _newestFirst = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _service.load();
    if (!mounted) return;
    setState(() {
      _nicknameController.text = settings.nickname;
      _newestFirst = settings.newestFirst;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.save(
      AppSettings(
        nickname: _nicknameController.text.trim(),
        newestFirst: _newestFirst,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Suporter')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nicknameController,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Nama panggilan',
                    helperText: 'Dipakai untuk sapaan di Catatan Laga',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Catatan terbaru di atas'),
                  subtitle: const Text('Matikan untuk urutan terlama dulu'),
                  value: _newestFirst,
                  onChanged: (value) => setState(() => _newestFirst = value),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('Simpan')),
              ],
            ),
    );
  }
}
