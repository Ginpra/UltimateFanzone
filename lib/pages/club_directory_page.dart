import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../model/club_info.dart';
import '../service/football_service.dart';
import '../service/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/club_crest.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/info_banner.dart';
import 'club_detail_page.dart';

/// Direktori 20 klub dalam kisi dua kolom, dengan kolom pencarian. Ketuk
/// klub untuk membuka profil detailnya. Modul: V (data lewat service), II, III.
class ClubDirectoryPage extends StatefulWidget {
  const ClubDirectoryPage({super.key});

  @override
  State<ClubDirectoryPage> createState() => _ClubDirectoryPageState();
}

class _ClubDirectoryPageState extends State<ClubDirectoryPage> {
  final _service = FootballService();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  FootballData<ClubInfo>? _clubs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clubs = await _service.getClubs(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _clubs = clubs;
        _loading = false;
      });
    } on FootballException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<ClubInfo> _filtered() {
    final all = _clubs?.items ?? [];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (c) =>
              c.shortName.toLowerCase().contains(q) ||
              c.name.toLowerCase().contains(q) ||
              c.tla.toLowerCase().contains(q),
        )
        .toList();
  }

  static const double _cardHeight = 196;
  static const double _cardTextExtra = 48;

  Widget _clubCard(ClubInfo club, String? favorite) {
    final theme = Theme.of(context);
    final isFavorite = club.shortName == favorite;
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubDetailPage(clubName: club.shortName),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              size: 18,
              color: isFavorite ? context.fz.accent : context.fz.textMuted,
            ),
          ),
          ClubCrest(name: club.shortName, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            club.shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            club.venue ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.fz.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    final list = _filtered();
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return Column(
      children: [
        if (_clubs?.source == DataSource.sample)
          const InfoBanner(
            icon: Icons.info_outline,
            text: 'Profil dasar. Pelatih dan skuad butuh FOOTBALL_API_KEY.',
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Cari klub',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Klub tidak ditemukan',
                  message: 'Coba nama lain atau kode tiga huruf, mis. ARS.',
                )
              : ValueListenableBuilder<String?>(
                  valueListenable: SettingsService.favoriteNotifier,
                  builder: (context, favorite, _) => GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    // Tinggi kartu tetap (bukan rasio) dan ikut ukuran huruf
                    // sistem, supaya isi kartu tidak overflow di HP berhuruf besar.
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisExtent:
                          _cardHeight + _cardTextExtra * (textScale - 1),
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => FadeSlideIn(
                      index: i % 8,
                      child: _clubCard(list[i], favorite),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direktori Klub'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(refresh: true),
          ),
        ],
      ),
      body: _body(),
    );
  }
}
