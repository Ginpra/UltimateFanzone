import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../core/format.dart';

/// Hitung mundur ke [kickoffUtc] dalam blok emas ala papan skor.
/// Memiliki Timer sendiri, jadi hanya blok ini yang digambar ulang tiap detik.
class CountdownBlock extends StatefulWidget {
  const CountdownBlock({super.key, required this.kickoffUtc});

  final DateTime kickoffUtc;

  @override
  State<CountdownBlock> createState() => _CountdownBlockState();
}

class _CountdownBlockState extends State<CountdownBlock> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    _remaining = widget.kickoffUtc.difference(DateTime.now().toUtc());
  }

  @override
  void didUpdateWidget(covariant CountdownBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kickoffUtc != widget.kickoffUtc) _update();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fz = context.fz;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fz.accent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        formatCountdown(_remaining),
        style: textTheme.titleLarge?.copyWith(color: fz.onAccent),
      ),
    );
  }
}
