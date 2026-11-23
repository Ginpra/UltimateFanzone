import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/reflex_rules.dart';
import '../service/settings_service.dart';

/// Refleks Kiper: bola muncul di salah satu dari 6 zona gawang, tepuk zona
/// itu sebelum waktunya habis. Salah tepuk atau telat mengurangi nyawa.
///
/// Modul: III (state dan setState), VI (skor terbaik di SharedPreferences).
class ReflexPage extends StatefulWidget {
  const ReflexPage({super.key});

  @override
  State<ReflexPage> createState() => _ReflexPageState();
}

class _ReflexPageState extends State<ReflexPage> {
  final _settings = SettingsService();
  final _random = Random();
  Timer? _timer;

  bool _running = false;
  bool _gameOver = false;
  int _score = 0;
  int _lives = reflexStartLives;
  int _limitMs = reflexStartLimitMs;
  int? _target;
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final best = await _settings.loadBestReflex();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _gameOver = false;
      _score = 0;
      _lives = reflexStartLives;
      _limitMs = reflexStartLimitMs;
    });
    _nextBall();
  }

  void _nextBall() {
    _timer?.cancel();
    setState(() => _target = _random.nextInt(6));
    _timer = Timer(Duration(milliseconds: _limitMs), _miss);
  }

  void _miss() {
    _timer?.cancel();
    setState(() => _lives -= 1);
    if (_lives <= 0) {
      _finish();
    } else {
      _nextBall();
    }
  }

  void _tapZone(int zone) {
    if (!_running) return;
    if (zone == _target) {
      _timer?.cancel();
      setState(() {
        _score += 1;
        _limitMs = nextReflexLimit(_limitMs);
      });
      _nextBall();
    } else {
      _miss();
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final isNewBest = _score > _best;
    if (isNewBest) await _settings.saveBestReflex(_score);
    if (!mounted) return;
    setState(() {
      _running = false;
      _gameOver = true;
      _target = null;
      if (isNewBest) _best = _score;
    });
  }

  Widget _zone(int index) {
    final scheme = Theme.of(context).colorScheme;
    final hasBall = _target == index;
    return InkWell(
      onTap: () => _tapZone(index),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hasBall
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outline),
        ),
        child: Center(
          child: hasBall ? const Icon(Icons.sports_soccer, size: 40) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Refleks Kiper')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Skor'),
                        Text('$_score', style: textTheme.headlineSmall),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Level'),
                        Text(
                          '${reflexLevel(_score)}',
                          style: textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Terbaik'),
                        Text('$_best', style: textTheme.headlineSmall),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Nyawa'),
                        Row(
                          children: [
                            for (var i = 0; i < reflexStartLives; i++)
                              Icon(
                                i < _lives
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (var i = 0; i < 6; i++) _zone(i)],
              ),
            ),
            const SizedBox(height: 16),
            if (_gameOver)
              Text(
                'Game selesai! Skormu $_score.',
                style: textTheme.titleMedium,
              ),
            if (_running) Text('Waktu menepis: $_limitMs ms'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _running ? null : _start,
              child: Text(_gameOver ? 'Main lagi' : 'Mulai'),
            ),
          ],
        ),
      ),
    );
  }
}
