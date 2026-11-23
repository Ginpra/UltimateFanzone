import 'package:flutter/material.dart';

import '../core/app_tokens.dart';

/// Pita kecil di atas daftar untuk memberi tahu asal data (contoh / tersimpan).
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fz = context.fz;
    return Container(
      width: double.infinity,
      color: fz.accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fz.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
