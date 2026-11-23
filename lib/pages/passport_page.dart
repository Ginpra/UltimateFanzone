import 'package:flutter/material.dart';

import '../core/format.dart';
import '../model/stadium.dart';
import '../model/stamp.dart';
import '../service/location_service.dart';
import '../service/stamp_service.dart';

/// Paspor Suporter: kumpulkan stempel dari 20 stadion.
///
/// Cap lewat GPS hanya diterima bila kamu dalam jarak [stampRadiusMeters]
/// dari stadion. Mode demo mematikan pengecekan GPS (untuk presentasi).
/// Modul: VII (lokasi), VI (Hive), III (setState).
class PassportPage extends StatefulWidget {
  const PassportPage({super.key});

  @override
  State<PassportPage> createState() => _PassportPageState();
}

class _PassportPageState extends State<PassportPage> {
  final _stamps = StampService();
  final _location = LocationService();

  List<Stamp> _collected = [];
  bool _loading = true;
  bool _demoMode = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stamps = await _stamps.loadAll();
    if (!mounted) return;
    setState(() {
      _collected = stamps;
      _loading = false;
    });
  }

  Stamp? _stampFor(Stadium s) {
    for (final st in _collected) {
      if (st.stadium == s.name) return st;
    }
    return null;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _stamp(Stadium stadium) async {
    setState(() => _busy = true);
    try {
      if (!_demoMode) {
        final pos = await _location.getCurrentPosition();
        final distance = _location.distanceTo(pos, stadium);
        if (distance > stampRadiusMeters) {
          if (!mounted) return;
          _snack(
            'Kamu ${formatDistance(distance)} dari ${stadium.name}. '
            'Harus dalam ${stampRadiusMeters.round()} m.',
          );
          setState(() => _busy = false);
          return;
        }
      }
      await _stamps.add(
        Stamp(
          stadium: stadium.name,
          club: stadium.club,
          stampedAt: DateTime.now(),
          byGps: !_demoMode,
        ),
      );
      await _load();
      if (!mounted) return;
      _snack('Stempel ${stadium.name} didapat!');
    } on LocationException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paspor Suporter')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Stempel terkumpul'),
                        Text(
                          '${_collected.length} / ${stadiums.length}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mode demo (tanpa GPS)'),
                  subtitle: const Text(
                    'Cap stempel tanpa harus berada di stadion',
                  ),
                  value: _demoMode,
                  onChanged: (v) => setState(() => _demoMode = v),
                ),
                for (final s in stadiums)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _stampFor(s) != null
                            ? Icons.verified
                            : Icons.circle_outlined,
                      ),
                      title: Text(s.name),
                      subtitle: Text(
                        _stampFor(s) == null
                            ? '${s.club} · ${s.city}'
                            : 'Dicap ${formatDateTime(_stampFor(s)!.stampedAt)}'
                                  '${_stampFor(s)!.byGps ? '' : ' (demo)'}',
                      ),
                      trailing: _stampFor(s) != null
                          ? null
                          : OutlinedButton(
                              onPressed: _busy ? null : () => _stamp(s),
                              child: const Text('Cap'),
                            ),
                    ),
                  ),
              ],
            ),
    );
  }
}
