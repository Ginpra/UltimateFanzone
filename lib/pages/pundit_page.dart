import 'package:flutter/material.dart';

import '../service/gemini_service.dart';
import '../service/settings_service.dart';

/// Pundit AI: tanya jawab sepak bola dengan Gemini (Modul V, HTTP POST).
///
/// Percakapan hanya disimpan di layar ini (hilang saat layar ditutup).
class PunditPage extends StatefulWidget {
  const PunditPage({super.key});

  @override
  State<PunditPage> createState() => _PunditPageState();
}

class _PunditPageState extends State<PunditPage> {
  final _gemini = GeminiService();
  final _settings = SettingsService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatTurn> _turns = [];
  String _club = 'Premier League';
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadClub() async {
    final favorite = await _settings.loadFavoriteClub();
    if (!mounted || favorite == null) return;
    setState(() => _club = favorite);
  }

  String get _systemInstruction =>
      'Kamu adalah pundit sepak bola untuk penggemar $_club. '
      'Jawab dalam bahasa Indonesia yang santai dan ringkas (maksimal 120 kata). '
      'Jangan mengarang skor, statistik, atau berita yang tidak kamu ketahui; '
      'kalau tidak yakin, katakan terus terang.';

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _turns.add(ChatTurn(role: 'user', text: question));
      _error = null;
    });
    await _ask();
  }

  /// Mengirim riwayat percakapan; dipakai juga oleh tombol "Coba lagi".
  Future<void> _ask() async {
    setState(() => _sending = true);
    try {
      final answer = await _gemini.ask(
        systemInstruction: _systemInstruction,
        turns: _turns,
      );
      if (!mounted) return;
      setState(() {
        _turns.add(ChatTurn(role: 'model', text: answer));
        _sending = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _bubble(ChatTurn turn) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(turn.text),
      ),
    );
  }

  Widget _suggestions() {
    final questions = [
      'Analisis performa $_club musim ini',
      'Siapa pemain kunci $_club?',
      'Apa kelemahan $_club saat ini?',
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanya pundit tentang $_club:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in questions)
                ActionChip(label: Text(q), onPressed: () => _send(q)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tanya Pundit')),
      body: Column(
        children: [
          Expanded(
            child: _turns.isEmpty
                ? _suggestions()
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [for (final t in _turns) _bubble(t)],
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Pundit sedang berpikir...'),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _ask, child: const Text('Coba lagi')),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Tanya soal sepak bola...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kirim',
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : () => _send(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
