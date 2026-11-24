import 'package:flutter/material.dart';

import '../core/crest_registry.dart';
import '../model/stadium.dart';

/// Logo klub dari API (lewat [CrestRegistry]) di atas piringan terang supaya
/// logo gelap tetap terbaca. Bila logo belum ada atau gagal dimuat (mis.
/// berformat SVG), yang tampil lencana warna klub dengan kode tiga huruf.
class ClubCrest extends StatelessWidget {
  const ClubCrest({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  Widget _badge(BuildContext context) {
    final club = stadiumOfClub(name);
    final scheme = Theme.of(context).colorScheme;
    final background = club == null
        ? scheme.surfaceContainerHighest
        : Color(club.color);
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final trimmed = name.trim();
    final code =
        club?.tla ??
        (trimmed.length >= 3 ? trimmed.substring(0, 3) : trimmed).toUpperCase();
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: club == null ? scheme.onSurface : foreground,
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = CrestRegistry.urlFor(name);
    return Semantics(
      label: 'Logo $name',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _badge(context),
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame == null && !wasSynchronouslyLoaded) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: EdgeInsets.all(size * 0.12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFEA),
                      shape: BoxShape.circle,
                    ),
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
