import 'package:flutter/material.dart';

import '../model/stadium.dart';

/// Lencana bundar klub: warna klub dan kode tiga huruf (mis. ARS).
/// Nama yang tidak dikenal memakai tiga huruf pertama dan warna netral.
class ClubCrest extends StatelessWidget {
  const ClubCrest({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
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
    return Semantics(
      label: 'Lencana $name',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
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
      ),
    );
  }
}
