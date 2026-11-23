import 'dart:math';

import 'package:flutter/material.dart';

/// Muncul dengan fade dan geser kecil dari bawah, sekali saat pertama dibuat.
/// [index] memberi jeda bertingkat: item lebih bawah selesai sedikit lebih
/// lambat, jadi daftar terasa mengalir tanpa Timer.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Hormati pengaturan "kurangi animasi" di HP.
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final extra = min(index, 8) * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + extra),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
