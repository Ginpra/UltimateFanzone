import 'package:flutter/material.dart';

import '../core/format.dart';
import '../model/football_match.dart';
import '../model/prediction.dart';
import '../service/football_service.dart';
import '../service/prediction_service.dart';
import '../widgets/error_state.dart';
import '../widgets/score_picker_dialog.dart';

/// Prediksi skor: tebak laga mendatang; poin setelah laga selesai (persis 3, hasil benar 1).
/// Modul: V, VI (Hive), III.
class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _footballService = FootballService();
  final _predictionService = PredictionService();

  bool _loading = true;
  String? _error;
  List<FootballMatch> _matches = [];
  List<Prediction> _predictions = [];

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
      final data = await _footballService.getMatches();
      final predictions = await _predictionService.loadAll();
      if (!mounted) return;
      setState(() {
        _matches = data.items;
        _predictions = predictions;
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

  Prediction? _predictionFor(int matchId) {
    for (final p in _predictions) {
      if (p.matchId == matchId) return p;
    }
    return null;
  }

  Future<void> _predict(FootballMatch match) async {
    final old = _predictionFor(match.id);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (_) => ScorePickerDialog(
        homeName: match.homeName,
        awayName: match.awayName,
        initialHome: old?.home ?? 0,
        initialAway: old?.away ?? 0,
      ),
    );
    if (result == null) return;
    await _predictionService.save(
      Prediction(
        matchId: match.id,
        label: match.label,
        kickoffUtc: match.kickoffUtc,
        home: result[0],
        away: result[1],
        createdAt: DateTime.now(),
      ),
    );
    await _load();
  }

  Widget _upcomingTab() {
    final now = DateTime.now().toUtc();
    final upcoming =
        _matches
            .where((m) => !m.isFinished && m.kickoffUtc.isAfter(now))
            .toList()
          ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));
    if (upcoming.isEmpty) {
      return const Center(child: Text('Tidak ada laga mendatang.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcoming.length,
      itemBuilder: (context, i) {
        final m = upcoming[i];
        final p = _predictionFor(m.id);
        return Card(
          child: ListTile(
            title: Text(m.label),
            subtitle: Text(formatDateTime(m.kickoffUtc)),
            trailing: p == null
                ? const Text('Prediksi')
                : Text(
                    '${p.home} - ${p.away}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
            onTap: () => _predict(m),
          ),
        );
      },
    );
  }

  Widget _historyTab() {
    final sorted = List<Prediction>.of(_predictions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    var total = 0;
    final rows = <Widget>[];
    for (final p in sorted) {
      FootballMatch? match;
      for (final m in _matches) {
        if (m.id == p.matchId) match = m;
      }
      final points = match == null ? null : p.pointsFor(match);
      total += points ?? 0;
      rows.add(
        Card(
          child: ListTile(
            title: Text(p.label),
            subtitle: Text(
              'Tebakanmu ${p.home} - ${p.away}'
              '${match != null && match.hasScore ? ' · Hasil ${match.homeScore} - ${match.awayScore}' : ''}',
            ),
            trailing: Text(
              points == null ? 'Menunggu' : '+$points poin',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total poin'),
                Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Belum ada tebakan.')),
          )
        else
          ...rows,
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    return TabBarView(children: [_upcomingTab(), _historyTab()]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prediksi Skor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Buat Prediksi'),
              Tab(text: 'Riwayat & Poin'),
            ],
          ),
        ),
        body: _body(),
      ),
    );
  }
}
