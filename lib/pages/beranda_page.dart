import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/app_tokens.dart';
import '../core/club_stats.dart';
import '../core/feature_tones.dart';
import '../core/format.dart';
import '../model/football_match.dart';
import '../model/standing_row.dart';
import '../service/football_service.dart';
import '../service/session_service.dart';
import '../service/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/club_crest.dart';
import '../widgets/countdown_block.dart';
import '../widgets/error_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/form_dot.dart';
import '../widgets/scrim_image.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/tone_icon.dart';
import 'club_detail_page.dart';
import 'notes_page.dart';
import 'prediction_page.dart';
import 'reminder_page.dart';

/// Beranda: laga berikutnya sebagai fokus, ringkasan klub favorit, pintasan, dan tiga
/// klub teratas. Ikut berubah lewat [SettingsService.favoriteNotifier].
class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key, required this.onOpenLaga});

  /// Pindah ke tab Laga (untuk memilih klub favorit).
  final VoidCallback onOpenLaga;

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _football = FootballService();
  final _session = SessionService();
  final _settings = SettingsService();

  bool _loading = true;
  String? _error;
  String _username = '';
  String _nickname = '';
  List<FootballMatch> _matches = [];
  List<StandingRow> _standings = [];

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _session.currentUser();
      final settings = await _settings.load();
      final matches = await _football.getMatches();
      final standings = await _football.getStandings();
      if (!mounted) return;
      setState(() {
        _username = user ?? '';
        _nickname = settings.nickname;
        _matches = matches.items;
        _standings = standings.items;
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

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _hero(String? favorite) {
    final theme = Theme.of(context);
    final name = _nickname.isNotEmpty ? _nickname : _username;
    final next = favorite == null
        ? nextAnyMatch(_matches, DateTime.now().toUtc())
        : nextMatch(_matches, favorite, DateTime.now().toUtc());
    return ScrimImage(
      assetPath: AppImages.heroMalamLaga,
      height: 340,
      borderRadius: 0,
      scrim: 0.75,
      showPitchPattern: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                name.isEmpty ? 'Halo, suporter' : 'Halo, $name',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                favorite == null
                    ? 'Pilih klub favoritmu di tab Laga'
                    : 'Malam ini bersama $favorite',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              _nextMatchCard(next),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextMatchCard(FootballMatch? next) {
    final theme = Theme.of(context);
    if (next == null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.event_busy_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _loading ? 'Memuat jadwal...' : 'Belum ada laga mendatang.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      onTap: () => _push(const ReminderPage()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laga berikutnya',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.fz.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ClubCrest(name: next.homeName, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${next.homeName}  vs  ${next.awayName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClubCrest(name: next.awayName, size: 40),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CountdownBlock(kickoffUtc: next.kickoffUtc),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '${formatDayHeader(next.kickoffUtc)}, ${formatTimeOnly(next.kickoffUtc)}\nTekan untuk pasang pengingat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.fz.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _favoriteSummary(String? favorite) {
    if (favorite == null) {
      return AppCard(
        onTap: widget.onOpenLaga,
        child: Row(
          children: [
            const Icon(Icons.star_border),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Pilih klub favorit untuk melihat peringkat dan form-nya.',
              ),
            ),
            Icon(Icons.chevron_right, color: context.fz.textMuted),
          ],
        ),
      );
    }
    StandingRow? row;
    for (final r in _standings) {
      if (r.team == favorite) row = r;
    }
    final form = lastFinished(_matches, favorite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(label: 'Peringkat', value: row?.position ?? 0),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(label: 'Poin', value: row?.points ?? 0),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(label: 'Laga main', value: row?.played ?? 0),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text('Form', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            if (form.isEmpty)
              const Text('Belum ada laga selesai.')
            else
              for (final m in form)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FormDot(result: resultFor(m, favorite)!),
                ),
            const Spacer(),
            TextButton(
              onPressed: () => _push(ClubDetailPage(clubName: favorite)),
              child: const Text('Profil klub'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActions() {
    final actions = <_Quick>[
      _Quick(
        Icons.scoreboard_outlined,
        'Prediksi',
        FeatureTone.play,
        () => _push(const PredictionPage()),
      ),
      _Quick(
        Icons.edit_note,
        'Catatan',
        FeatureTone.personal,
        () => _push(const NotesPage()),
      ),
      _Quick(
        Icons.notifications_active_outlined,
        'Pengingat',
        FeatureTone.personal,
        () => _push(const ReminderPage()),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              onTap: actions[i].onTap,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Column(
                children: [
                  ToneIcon(icon: actions[i].icon, tone: actions[i].tone),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    actions[i].label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _topThree() {
    final top = _standings.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tiga teratas',
          actionLabel: 'Semua',
          onAction: widget.onOpenLaga,
        ),
        for (final r in top)
          InkWell(
            onTap: () => _push(ClubDetailPage(clubName: r.team)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${r.position}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ClubCrest(name: r.team, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      r.team,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    '${r.points} poin',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<String?>(
        valueListenable: SettingsService.favoriteNotifier,
        builder: (context, favorite, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _hero(favorite),
              if (_error != null)
                SizedBox(
                  height: 260,
                  child: ErrorState(message: _error!, onRetry: _load),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(child: _favoriteSummary(favorite)),
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(index: 1, child: _quickActions()),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeSlideIn(index: 2, child: _topThree()),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Quick {
  const _Quick(this.icon, this.label, this.tone, this.onTap);

  final IconData icon;
  final String label;
  final FeatureTone tone;
  final VoidCallback onTap;
}
