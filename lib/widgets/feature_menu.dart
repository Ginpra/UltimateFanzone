import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import 'app_card.dart';
import 'fade_slide_in.dart';
import 'scrim_image.dart';

/// Satu fitur di menu. [builder] membuat layar tujuan.
class MenuItem {
  const MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

void _open(BuildContext context, MenuItem item) {
  Navigator.push(context, MaterialPageRoute(builder: item.builder));
}

/// Halaman menu: header bergambar, satu fitur unggulan yang besar (dengan
/// gambar latar), lalu daftar fitur lain yang ringkas. Bentuknya sengaja
/// berbeda antara unggulan dan sisanya supaya yang utama langsung terlihat.
class FeatureMenu extends StatelessWidget {
  const FeatureMenu({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headerAsset,
    required this.featured,
    required this.featuredAsset,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String headerAsset;
  final MenuItem featured;
  final String featuredAsset;
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fz = context.fz;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScrimImage(
          assetPath: headerAsset,
          height: 150,
          borderRadius: 0,
          scrim: 0.7,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Semantics(
                  button: true,
                  label: featured.title,
                  child: GestureDetector(
                    onTap: () => _open(context, featured),
                    child: ScrimImage(
                      assetPath: featuredAsset,
                      height: 170,
                      scrim: 0.62,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(featured.icon, color: fz.accent, size: 28),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              featured.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              featured.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < items.length; i++)
                FadeSlideIn(
                  index: i + 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () => _open(context, items[i]),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            items[i].icon,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[i].title,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  items[i].subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: fz.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: fz.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
