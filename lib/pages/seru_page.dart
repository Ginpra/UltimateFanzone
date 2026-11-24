import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/feature_tones.dart';
import '../widgets/feature_menu.dart';
import 'passport_page.dart';
import 'prediction_page.dart';
import 'pundit_page.dart';
import 'reflex_page.dart';

/// Tab Seru: permainan dan interaksi ringan.
class SeruPage extends StatelessWidget {
  const SeruPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FeatureMenu(
        title: 'Seru-seruan',
        subtitle: 'Tebak, tangkap, kumpulkan, dan tanya pundit',
        headerAsset: AppImages.headerSeru,
        featuredAsset: AppImages.gameGoal,
        featured: MenuItem(
          icon: Icons.sports_handball_outlined,
          title: 'Refleks Kiper',
          subtitle: 'Tepuk zona tempat bola datang sebelum waktu habis',
          tone: FeatureTone.play,
          builder: (_) => const ReflexPage(),
        ),
        items: [
          MenuItem(
            icon: Icons.scoreboard_outlined,
            title: 'Prediksi Skor',
            subtitle: 'Tebak skor laga mendatang dan kumpulkan poin',
            tone: FeatureTone.play,
            builder: (_) => const PredictionPage(),
          ),
          MenuItem(
            icon: Icons.verified_outlined,
            title: 'Paspor Suporter',
            subtitle: 'Kumpulkan stempel dari 20 stadion',
            tone: FeatureTone.play,
            builder: (_) => const PassportPage(),
          ),
          MenuItem(
            icon: Icons.psychology_alt_outlined,
            title: 'Tanya Pundit',
            subtitle: 'Tanya jawab sepak bola dengan Gemini',
            tone: FeatureTone.play,
            builder: (_) => const PunditPage(),
          ),
        ],
      ),
    );
  }
}
