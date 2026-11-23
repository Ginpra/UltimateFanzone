import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_tokens.dart';
import '../core/format.dart';
import '../model/stadium.dart';
import '../service/location_service.dart';
import '../widgets/club_crest.dart';

/// Peta Stadion (Modul VII LBS): 20 stadion di peta OpenStreetMap, posisimu
/// dari GPS, dan jarak ke tiap stadion. Ketuk penanda atau baris daftar untuk
/// memilih stadion; garis putus-putus menghubungkannya dengan lokasimu.
class StadiumPage extends StatefulWidget {
  const StadiumPage({super.key});

  @override
  State<StadiumPage> createState() => _StadiumPageState();
}

class _StadiumPageState extends State<StadiumPage> {
  final _location = LocationService();
  final _mapController = MapController();

  Position? _position;
  Stadium? _selected;
  bool _loading = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng? get _me {
    final p = _position;
    return p == null ? null : LatLng(p.latitude, p.longitude);
  }

  double? _distanceTo(Stadium s) {
    final p = _position;
    return p == null ? null : _location.distanceTo(p, s);
  }

  Future<void> _findMe() async {
    setState(() => _loading = true);
    try {
      final pos = await _location.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = pos;
        _loading = false;
      });
      _focus();
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _select(Stadium s) {
    setState(() => _selected = s);
    _focus();
  }

  /// Menggeser peta: ke stadion terpilih, atau memuat lokasimu dan stadion
  /// sekaligus bila lokasimu sudah diketahui.
  void _focus() {
    final s = _selected;
    final me = _me;
    if (s == null) {
      if (me != null) _mapController.move(me, 12);
      return;
    }
    final target = LatLng(s.lat, s.lng);
    if (me == null) {
      _mapController.move(target, 14);
    } else {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([me, target]),
          padding: const EdgeInsets.all(48),
          maxZoom: 15,
        ),
      );
    }
  }

  Widget _marker(Stadium s) {
    final selected = _selected == s;
    final color = Color(s.color);
    return GestureDetector(
      onTap: () => _select(s),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: selected ? 4 : 3),
        ),
        child: Icon(
          Icons.sports_soccer,
          size: selected ? 26 : 20,
          color: color,
        ),
      ),
    );
  }

  Widget _map() {
    final me = _me;
    final selected = _selected;
    final scheme = Theme.of(context).colorScheme;
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(52.8, -1.6),
        initialZoom: 5.4,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ultimate_fanzone',
        ),
        if (me != null && selected != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [me, LatLng(selected.lat, selected.lng)],
                strokeWidth: 3,
                color: scheme.primary,
                pattern: StrokePattern.dashed(segments: const [8, 6]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final s in stadiums)
              Marker(
                point: LatLng(s.lat, s.lng),
                width: selected == s ? 44 : 36,
                height: selected == s ? 44 : 36,
                child: _marker(s),
              ),
            if (me != null)
              Marker(
                point: me,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(Icons.person, color: scheme.onPrimary, size: 22),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fz = context.fz;
    final sorted = List<Stadium>.of(stadiums);
    if (_position != null) {
      sorted.sort((a, b) => _distanceTo(a)!.compareTo(_distanceTo(b)!));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Stadion')),
      body: Column(
        children: [
          SizedBox(height: 300, child: _map()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _position == null
                        ? 'Ketuk penanda untuk melihat stadion.'
                        : 'Lokasimu: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fz.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _loading ? null : _findMe,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_loading ? 'Mencari' : 'Cari lokasiku'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final s = sorted[i];
                final distance = _distanceTo(s);
                final isSelected = _selected == s;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: isSelected ? fz.surfaceHigh : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      leading: ClubCrest(name: s.club, size: 36),
                      title: Text(s.name),
                      subtitle: Text('${s.club} · ${s.city}'),
                      trailing: distance == null
                          ? null
                          : Text(
                              formatDistance(distance),
                              style: theme.textTheme.titleSmall,
                            ),
                      onTap: () => _select(s),
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
