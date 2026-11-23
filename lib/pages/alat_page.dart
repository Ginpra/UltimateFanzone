import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../widgets/feature_menu.dart';
import 'away_day_page.dart';
import 'club_profile_page.dart';
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
        subtitle: 'Peta, catatan, anggaran, dan pengingat',
        headerAsset: AppImages.headerAlat,
        featuredAsset: AppImages.headerLaga,
        featured: MenuItem(
          icon: Icons.map_outlined,
          title: 'Peta Stadion',
          subtitle:
              'Lihat 20 stadion di peta dan hitung jaraknya dari lokasimu',
          builder: (_) => const StadiumPage(),
        ),
        items: [
          MenuItem(
            icon: Icons.shield_outlined,
            title: 'Profil Klub Favorit',
            subtitle: 'Peringkat, form 5 laga, laga berikutnya, top skor',
            builder: (_) => const ClubProfilePage(),
          ),
          MenuItem(
            icon: Icons.currency_exchange,
            title: 'Away Day',
            subtitle: 'Catat pengeluaran dan anggaran perjalanan tandang',
            builder: (_) => const AwayDayPage(),
          ),
          MenuItem(
            icon: Icons.notifications_active_outlined,
            title: 'Pengingat Laga',
            subtitle: 'Notifikasi sebelum kickoff',
            builder: (_) => const ReminderPage(),
          ),
          MenuItem(
            icon: Icons.edit_note,
            title: 'Catatan Laga',
            subtitle: 'Catatan pribadi tiap pertandingan',
            builder: (_) => const NotesPage(),
          ),
          MenuItem(
            icon: Icons.sos_outlined,
            title: 'SOS Darurat',
            subtitle: 'Ambil dan salin lokasimu saat darurat',
            builder: (_) => const SosPage(),
          ),
        ],
      ),
    );
  }
}
