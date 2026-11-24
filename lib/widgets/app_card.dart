import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import 'press_scale.dart';

/// Kartu seragam bertema aplikasi; bila [onTap] ada, kartu mengecil saat ditekan.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  /// Isi yang ditampilkan di dalam kartu.
  final Widget child;

  /// Aksi saat kartu diketuk; bila null kartu hanya bersifat informatif dan
  /// tidak dapat diklik.
  final VoidCallback? onTap;

  /// Padding internal kartu, default [AppSpacing.lg].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return Card(margin: EdgeInsets.zero, child: content);
    }
    // Kartu yang bisa diketuk: ripple di dalam kartu dan mengecil saat ditekan.
    return PressScale(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}
