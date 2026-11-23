import '../model/match_note.dart';
import 'local_list_store.dart';

/// Catatan laga (Hive lewat LocalListStore).
class NotesService {
  final LocalListStore _store = LocalListStore('notes_v1');

  Future<List<MatchNote>> loadAll() async {
    final raw = await _store.load();
    return raw.map(MatchNote.fromJson).toList();
  }

  Future<void> _saveAll(List<MatchNote> notes) =>
      _store.save(notes.map((n) => n.toJson()).toList());

  /// Tambah catatan baru, atau ganti yang punya id sama (ubah).
  Future<void> upsert(MatchNote note) async {
    final notes = await loadAll();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    await _saveAll(notes);
  }

  Future<void> delete(String id) async {
    final notes = await loadAll();
    notes.removeWhere((n) => n.id == id);
    await _saveAll(notes);
  }
}
