import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../core/format.dart';
import '../model/app_settings.dart';
import '../model/match_note.dart';
import '../service/notes_service.dart';
import '../service/settings_service.dart';
import '../widgets/empty_state.dart';
import 'note_form_page.dart';
import 'settings_page.dart';

/// Daftar catatan laga pribadi.
/// Modul: II, III, IV (push dan hasil pop), VI (Hive dan SharedPreferences).
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _notesService = NotesService();
  final _settingsService = SettingsService();

  List<MatchNote> _notes = [];
  AppSettings _settings = const AppSettings(nickname: '', newestFirst: true);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _notesService.loadAll();
    final settings = await _settingsService.load();
    notes.sort(
      (a, b) => settings.newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _openForm([MatchNote? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(existing: existing)),
    );
    if (saved == true) await _load();
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (saved == true) await _load();
  }

  Future<bool> _confirmDelete(MatchNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Catatan "${note.match}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await _notesService.delete(note.id);
    if (!mounted) return true;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _settings.nickname;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Laga'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (nickname.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Halo, $nickname!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                Expanded(
                  child: _notes.isEmpty
                      ? const EmptyState(
                          icon: Icons.edit_note,
                          title: 'Belum ada catatan',
                          message: 'Tekan tombol Catatan untuk menulis yang pertama.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: _notes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Dismissible(
                              key: ValueKey(note.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(note),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: scheme.error,
                                child: Icon(
                                  Icons.delete_outline,
                                  color: scheme.onError,
                                ),
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: ListTile(
                                  title: Text(note.match),
                                  subtitle: Text(
                                    '${note.note}\n${formatDateTime(note.createdAt)}',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isThreeLine: true,
                                  onTap: () => _openForm(note),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
