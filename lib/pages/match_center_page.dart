import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/app_tokens.dart';
import '../core/club_stats.dart';
import '../core/format.dart';
import '../model/football_match.dart';
import '../model/scorer_row.dart';
import '../model/standing_row.dart';
import '../service/football_service.dart';
import '../service/settings_service.dart';
import '../widgets/club_crest.dart';
import '../widgets/error_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/info_banner.dart';
import '../widgets/match_tile.dart';
import '../widgets/scrim_image.dart';

/// Jadwal (dikelompokkan per hari), klasemen, dan top skor Premier League.
///
/// Pola Modul V: data diambil di service (bukan di widget); layar hanya
/// menyimpan status `_loading`, `_error`, dan data di State lalu memanggil
/// `setState` setelah data siap. Klub favorit disimpan di SharedPreferences.
class MatchCenterPage extends StatefulWidget {
  const MatchCenterPage({super.key});

  @override
  State<MatchCenterPage> createState() => _MatchCenterPageState();
}

class _MatchCenterPageState extends State<MatchCenterPage> {
  final _service = FootballService();
  final _settings = SettingsService();

  bool _loading = true;
  String? _error;
  FootballData<FootballMatch>? _matches;
  FootballData<StandingRow>? _standings;
  FootballData<ScorerRow>? _scorers;
  String _filter = 'upcoming';

  String? get _favorite => SettingsService.favoriteNotifier.value;

  @override
  void initState() {
    super.initState();
    SettingsService.favoriteNotifier.addListener(_onFavoriteChanged);
    _load();
  }

  @override
  void dispose() {
    SettingsService.favoriteNotifier.removeListener(_onFavoriteChanged);
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load({bool refresh = false, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final matches = await _service.getMatches(refresh: refresh);
      final standings = await _service.getStandings(refresh: refresh);
      final scorers = await _service.getScorers(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _standings = standings;
        _scorers = scorers;
        _error = null;
        _loading = false;
      });
    } on FootballException catch (e) {
      if (!mounted) return;
      if (silent && _matches != null) {
        // Tarik-untuk-muat gagal: data lama tetap tampil, kabari lewat snackbar.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  bool _involvesFavorite(FootballMatch m) =>
      _favorite != null && (m.homeName == _favorite || m.awayName == _favorite);

  List<FootballMatch> _filteredMatches() {
    final all = List<FootballMatch>.of(_matches?.items ?? []);
    if (_filter == 'finished') {
      return all.where((m) => m.isFinished).toList();
    }
    if (_filter == 'favorite') {
      return all.where(_involvesFavorite).toList();
    }
    if (_filter == 'upcoming') {
      return all.where((m) => !m.isFinished).toList();
    }
    return all;
  }

  /// Memilih klub favorit dari daftar klub di klasemen.
  Future<void> _pickFavorite() async {
    final clubs = (_standings?.items ?? []).map((r) => r.team).toList();
    if (clubs.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Pilih klub favorit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final club in clubs)
              ListTile(
                leading: ClubCrest(name: club, size: 36),
                title: Text(club),
                trailing: club == _favorite ? const Icon(Icons.star) : null,
                onTap: () => Navigator.pop(ctx, club),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _settings.saveFavoriteClub(chosen);
  }

  Widget _banner() {
    final source = _matches?.source;
    if (source == DataSource.sample) {
      return const InfoBanner(
        icon: Icons.info_outline,
        text: 'Data contoh (FOOTBALL_API_KEY belum diisi).',
      );
    }
    if (source == DataSource.cache) {
      return const InfoBanner(
        icon: Icons.save_outlined,
        text: 'Menampilkan data tersimpan.',
      );
    }
    return const SizedBox.shrink();
  }

  Widget _scrollable(Widget child) => RefreshIndicator(
    onRefresh: () => _load(refresh: true, silent: true),
    child: child,
  );

  Widget _matchesTab() {
    final list = _filteredMatches();
    final groups = groupByDay(list);
    // Laga selesai: hari terbaru di atas; lainnya: hari terawal di atas.
    final ordered = _filter == 'finished' ? groups.reversed.toList() : groups;

    final items = <Object>[];
    for (final g in ordered) {
      items.add(g.key);
      items.addAll(_filter == 'finished' ? g.value.reversed : g.value);
    }

    final filters = <String, String>{
      'upcoming': 'Mendatang',
      'finished': 'Selesai',
      'all': 'Semua',
      if (_favorite != null) 'favorite': _favorite!,
    };

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final entry in filters.entries)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _scrollable(
            items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Tidak ada pertandingan.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      if (item is DateTime) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.lg,
                            bottom: AppSpacing.sm,
                          ),
                          child: Text(
                            formatDayHeader(item),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: context.fz.textMuted),
                          ),
                        );
                      }
                      final match = item as FootballMatch;
                      return FadeSlideIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: MatchTile(
                            match: match,
                            highlight: _involvesFavorite(match),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _standingsTab() {
    final rows = _standings?.items ?? [];
    final theme = Theme.of(context);
    final muted = context.fz.textMuted;
    if (rows.isEmpty) {
      return _scrollable(
        ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Klasemen belum tersedia.')),
          ],
        ),
      );
    }
    return _scrollable(
      ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const SizedBox(width: 3 + AppSpacing.sm),
                SizedBox(
                  width: 28,
                  child: Text('#', style: theme.textTheme.bodySmall),
                ),
                const SizedBox(width: 32 + AppSpacing.sm),
                Expanded(child: Text('Klub', style: theme.textTheme.bodySmall)),
                SizedBox(
                  width: 30,
                  child: Text('M', style: theme.textTheme.bodySmall),
                ),
                SizedBox(
                  width: 38,
                  child: Text('SG', style: theme.textTheme.bodySmall),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'Poin',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            FadeSlideIn(
              index: i,
              child: _standingRow(rows[i], rows.length, muted),
            ),
        ],
      ),
    );
  }

  /// Baris klasemen. Garis tipis di kiri: hijau untuk empat besar, merah untuk
  /// tiga terbawah (zona degradasi), seperti tabel liga pada umumnya.
  Widget _standingRow(StandingRow r, int total, Color muted) {
    final theme = Theme.of(context);
    final isFavorite = r.team == _favorite;
    Color? zone;
    if (r.position <= 4) {
      zone = Colors.green;
    } else if (total >= 18 && r.position > total - 3) {
      zone = Colors.red;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isFavorite ? context.fz.surfaceHigh : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: zone ?? Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 28,
            child: Text('${r.position}', style: theme.textTheme.titleSmall),
          ),
          ClubCrest(name: r.team, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              r.team,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isFavorite ? FontWeight.bold : null,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${r.played}',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${r.goalDiff}',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${r.points}',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scorersTab() {
    final rows = _scorers?.items ?? [];
    if (rows.isEmpty) {
      return _scrollable(
        ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Top skor belum tersedia.')),
          ],
        ),
      );
    }
    final theme = Theme.of(context);
    return _scrollable(
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          final assists = r.assists == null ? '' : ' · ${r.assists} assist';
          return FadeSlideIn(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.fz.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ClubCrest(name: r.team, size: 36),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.player,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${r.team}$assists',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.fz.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('${r.goals}', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    Widget content;
    if (_loading) {
      content = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      content = ErrorState(
        key: const ValueKey('error'),
        message: _error!,
        onRetry: () => _load(),
      );
    } else {
      content = Column(
        key: const ValueKey('content'),
        children: [
          _banner(),
          Expanded(
            child: TabBarView(
              children: [_matchesTab(), _standingsTab(), _scorersTab()],
            ),
          ),
        ],
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: content,
    );
  }

  Widget _header() {
    final theme = Theme.of(context);
    final favorite = _favorite;
    return ScrimImage(
      assetPath: AppImages.headerLaga,
      height: 160,
      borderRadius: 0,
      scrim: 0.7,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Pilih klub favorit',
                    color: Colors.white,
                    icon: Icon(
                      favorite == null ? Icons.star_border : Icons.star,
                    ),
                    onPressed: _loading ? null : _pickFavorite,
                  ),
                  IconButton(
                    tooltip: 'Muat ulang',
                    color: Colors.white,
                    icon: const Icon(Icons.refresh),
                    onPressed: _loading ? null : () => _load(refresh: true),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Match Center',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                favorite == null
                    ? 'Pilih klub favorit lewat ikon bintang'
                    : 'Klub favorit: $favorite',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            _header(),
            const TabBar(
              tabs: [
                Tab(text: 'Jadwal'),
                Tab(text: 'Klasemen'),
                Tab(text: 'Top Skor'),
              ],
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }
}
