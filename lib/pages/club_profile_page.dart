import 'package:flutter/material.dart';

import '../core/club_stats.dart';
import '../core/format.dart';
import '../model/football_match.dart';
import '../model/scorer_row.dart';
import '../model/standing_row.dart';
import '../service/football_service.dart';
import '../service/settings_service.dart';
import '../widgets/error_state.dart';

/// Profil klub favorit: peringkat, form 5 laga terakhir, laga berikutnya,
/// dan pencetak gol klub. Semua dihitung dari data yang sudah ada
/// (jadwal, klasemen, top skor), jadi tanpa permintaan API tambahan.
///
/// Modul: V (data dari service HTTP), VI (klub favorit di SharedPreferences),
/// II (Card, ListTile), III (setState).
class ClubProfilePage extends StatefulWidget {
  const ClubProfilePage({super.key});

  @override
  State<ClubProfilePage> createState() => _ClubProfilePageState();
}

class _ClubProfilePageState extends State<ClubProfilePage> {
  final _football = FootballService();
  final _settings = SettingsService();

  bool _loading = true;
  String? _error;
  String? _club;
  List<FootballMatch> _matches = [];
  List<StandingRow> _standings = [];
  List<ScorerRow> _scorers = [];

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
      final club = await _settings.loadFavoriteClub();
      final matches = await _football.getMatches();
      final standings = await _football.getStandings();
      final scorers = await _football.getScorers();
      if (!mounted) return;
      setState(() {
        _club = club;
        _matches = matches.items;
        _standings = standings.items;
        _scorers = scorers.items;
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

  Color _resultColor(String result) {
    if (result == 'W') return Colors.green;
    if (result == 'L') return Colors.red;
    return Colors.grey;
  }

  Widget _headerCard(String club) {
    StandingRow? row;
    for (final r in _standings) {
      if (r.team == club) row = r;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(club, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              row == null
                  ? 'Belum ada di klasemen.'
                  : 'Peringkat ${row.position} · ${row.points} poin · '
                        'main ${row.played} · selisih gol ${row.goalDiff}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard(String club) {
    final last = lastFinished(_matches, club);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form laga terakhir',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (last.isEmpty)
              const Text('Belum ada laga selesai.')
            else ...[
              Row(
                children: [
                  for (final m in last)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: _resultColor(resultFor(m, club)!),
                        child: Text(
                          resultFor(m, club)!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (final m in last)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.label),
                  trailing: Text('${m.homeScore} - ${m.awayScore}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nextCard(String club) {
    final next = nextMatch(_matches, club, DateTime.now().toUtc());
    return Card(
      child: ListTile(
        title: const Text('Laga berikutnya'),
        subtitle: Text(
          next == null
              ? 'Belum ada jadwal.'
              : '${next.label}\n${formatDateTime(next.kickoffUtc)}',
        ),
        isThreeLine: next != null,
      ),
    );
  }

  Widget _scorersCard(String club) {
    final own = _scorers.where((s) => s.team == club).take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pencetak gol klub',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (own.isEmpty)
              const Text('Belum ada pemain klub ini di daftar top skor.')
            else
              for (final s in own)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.player),
                  trailing: Text('${s.goals} gol'),
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
    final club = _club;
    if (club == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pilih klub favorit dulu di Match Center (ikon bintang).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _headerCard(club),
        _formCard(club),
        _nextCard(club),
        _scorersCard(club),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Klub Favorit')),
      body: _body(),
    );
  }
}
