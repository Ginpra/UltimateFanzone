import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../core/feature_tones.dart';

/// Ikon dalam kotak bersudut berwarna kategori fitur.
class ToneIcon extends StatelessWidget {
  const ToneIcon({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 44,
  });

  final IconData icon;
  final FeatureTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = tone.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
