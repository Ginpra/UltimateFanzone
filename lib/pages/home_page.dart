import 'package:flutter/material.dart';

import 'alat_page.dart';
import 'beranda_page.dart';
import 'match_center_page.dart';
import 'profile_page.dart';
import 'seru_page.dart';

/// Kerangka utama dengan bilah navigasi bawah lima tab.
/// Layar disimpan di IndexedStack supaya posisi gulir dan data tidak hilang
/// saat pindah tab; [_tick] memberi tahu Profil agar memuat ulang angkanya.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  int _tick = 0;

  void _select(int index) {
    setState(() {
      _index = index;
      _tick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          BerandaPage(onOpenLaga: () => _select(1)),
          const MatchCenterPage(),
          const SeruPage(),
          const AlatPage(),
          ProfilePage(refreshTick: _tick),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Laga',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Seru',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Alat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
