import '../model/stamp.dart';
import 'local_list_store.dart';

/// Stempel Paspor Suporter (Hive lewat LocalListStore, per akun).
class StampService {
  final LocalListStore _store = LocalListStore('stamps_v1');

  Future<List<Stamp>> loadAll() async {
    final raw = await _store.load();
    return raw.map(Stamp.fromJson).toList();
  }

  /// Simpan stempel. Stadion yang sudah dicap tidak dicap dua kali.
  Future<void> add(Stamp stamp) async {
    final all = await loadAll();
    if (all.any((s) => s.stadium == stamp.stadium)) return;
    all.add(stamp);
    await _store.save(all.map((s) => s.toJson()).toList());
  }
}
