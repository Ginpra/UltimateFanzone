import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/feature_tones.dart';
import '../widgets/feature_menu.dart';
import 'away_day_page.dart';
import 'club_directory_page.dart';
import 'notes_page.dart';
import 'reminder_page.dart';
import 'sos_page.dart';
import 'stadium_page.dart';

/// Tab Alat: fitur praktis untuk suporter.
class AlatPage extends StatelessWidget {
  const AlatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FeatureMenu(
        title: 'Alat Suporter',
        subtitle: 'Klub, peta, catatan, anggaran, dan pengingat',
        headerAsset: AppImages.headerAlat,
        featuredAsset: AppImages.headerLaga,
        featured: MenuItem(
          icon: Icons.shield_outlined,
          title: 'Direktori Klub',
          subtitle: 'Profil, pelatih, dan skuad 20 klub Premier League',
          tone: FeatureTone.info,
          builder: (_) => const ClubDirectoryPage(),
        ),
        items: [
          MenuItem(
            icon: Icons.map_outlined,
            title: 'Peta Stadion',
            subtitle: 'Lihat 20 stadion di peta dan hitung jaraknya',
            tone: FeatureTone.info,
            builder: (_) => const StadiumPage(),
          ),
          MenuItem(
            icon: Icons.currency_exchange,
            title: 'Away Day',
            subtitle: 'Catat pengeluaran dan anggaran perjalanan tandang',
            tone: FeatureTone.personal,
            builder: (_) => const AwayDayPage(),
          ),
          MenuItem(
            icon: Icons.notifications_active_outlined,
            title: 'Pengingat Laga',
            subtitle: 'Notifikasi sebelum kickoff',
            tone: FeatureTone.personal,
            builder: (_) => const ReminderPage(),
          ),
          MenuItem(
            icon: Icons.edit_note,
            title: 'Catatan Laga',
            subtitle: 'Catatan pribadi tiap pertandingan',
            tone: FeatureTone.personal,
            builder: (_) => const NotesPage(),
          ),
          MenuItem(
            icon: Icons.sos_outlined,
            title: 'SOS Darurat',
            subtitle: 'Ambil dan salin lokasimu saat darurat',
            tone: FeatureTone.safety,
            builder: (_) => const SosPage(),
          ),
        ],
      ),
    );
  }
}
