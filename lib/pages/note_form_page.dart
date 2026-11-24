import 'package:flutter/material.dart';

import '../model/match_note.dart';
import '../service/notes_service.dart';

/// Form tambah atau ubah catatan. Mengembalikan `true` lewat `Navigator.pop` bila tersimpan.
class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.existing});

  final MatchNote? existing;

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = NotesService();
  late final TextEditingController _matchController;
  late final TextEditingController _noteController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _matchController = TextEditingController(text: widget.existing?.match);
    _noteController = TextEditingController(text: widget.existing?.note);
  }

  @override
  void dispose() {
    _matchController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final old = widget.existing;
    final note = old == null
        ? MatchNote(
            id: now.millisecondsSinceEpoch.toString(),
            match: _matchController.text.trim(),
            note: _noteController.text.trim(),
            createdAt: now,
          )
        : old.copyWith(
            match: _matchController.text.trim(),
            note: _noteController.text.trim(),
          );

    await _service.upsert(note);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Ubah Catatan' : 'Catatan Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _matchController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Laga',
                hintText: 'Contoh: Arsenal vs Chelsea',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama laga wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Catatan minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
