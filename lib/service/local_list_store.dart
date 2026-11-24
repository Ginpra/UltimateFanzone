import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'session_service.dart';

/// Satu daftar JSON di Hive per akun (kunci `<baseKey>_<username>`), dipakai bersama
/// oleh service catatan, tebakan, pengeluaran, dan stempel.
class LocalListStore {
  LocalListStore(this.baseKey);

  final String baseKey;

  static const _boxName = 'local_lists';
  final SessionService _session = SessionService();

  Future<Box<String>> _openBox() {
    if (Hive.isBoxOpen(_boxName)) {
      return Future.value(Hive.box<String>(_boxName));
    }
    return Hive.openBox<String>(_boxName);
  }

  Future<String> _key() async {
    final user = await _session.currentUser() ?? 'tamu';
    return '${baseKey}_$user';
  }

  /// Data kosong atau rusak menghasilkan daftar kosong.
  Future<List<Map<String, dynamic>>> load() async {
    final box = await _openBox();
    final raw = box.get(await _key());
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Map<String, dynamic>> items) async {
    final box = await _openBox();
    await box.put(await _key(), jsonEncode(items));
  }
}
