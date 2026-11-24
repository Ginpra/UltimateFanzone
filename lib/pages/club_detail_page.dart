import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../core/club_stats.dart';
import '../core/format.dart';
import '../model/club_info.dart';
import '../model/football_match.dart';
import '../model/scorer_row.dart';
import '../model/stadium.dart';
import '../model/standing_row.dart';
import '../service/football_service.dart';
import '../service/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/club_crest.dart';
import '../widgets/error_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/form_dot.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

/// Profil detail satu klub: liga, form, laga berikutnya, info, pelatih, pencetak gol,
/// skuad. Info klub, pelatih, dan skuad butuh kunci API.
class ClubDetailPage extends StatefulWidget {
  const ClubDetailPage({super.key, required this.clubName});

  /// Nama singkat klub seperti yang dipakai API, mis. "Arsenal" atau "Man City".
  final String clubName;

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  final _service = FootballService();
  final _settings = SettingsService();

  bool _loading = true;
  String? _error;
  ClubInfo? _info;
  StandingRow? _standing;
  List<FootballMatch> _matches = [];
  List<ScorerRow> _scorers = [];

  Stadium? get _stadium => stadiumOfClub(widget.clubName);

  @override
  void initState() {
    super.initState();
    _load();
  }

  ClubInfo? _findInfo(List<ClubInfo> clubs) {
    for (final c in clubs) {
      if (c.shortName == widget.clubName) return c;
    }
    final target = _stadium;
    if (target == null) return null;
    for (final c in clubs) {
      if (stadiumOfClub(c.shortName) == target) return c;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clubs = await _service.getClubs();
      final matches = await _service.getMatches();
      final standings = await _service.getStandings();
      final scorers = await _service.getScorers();
      StandingRow? row;
      for (final r in standings.items) {
        if (r.team == widget.clubName) row = r;
      }
      if (!mounted) return;
      setState(() {
        _info = _findInfo(clubs.items);
        _standing = row;
        _matches = matches.items;
        _scorers = scorers.items
            .where((s) => s.team == widget.clubName)
            .toList();
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

  Future<void> _makeFavorite() async {
    await _settings.saveFavoriteClub(widget.clubName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.clubName} jadi klub favoritmu.')),
    );
  }

  Widget _header() {
    final theme = Theme.of(context);
    final stadium = _stadium;
    final band = stadium == null
        ? context.fz.surfaceHigh
        : Color(stadium.color);
    final onBand = ThemeData.estimateBrightnessForColor(band) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      width: double.infinity,
      color: band,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          ClubCrest(name: widget.clubName, size: 96),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _info?.name ?? widget.clubName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(color: onBand),
          ),
          if (stadium != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${stadium.name} · ${stadium.city}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: onBand),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsRow() {
    final row = _standing;
    if (row == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: StatTile(label: 'Peringkat', value: row.position),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(label: 'Poin', value: row.points),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatTile(label: 'Laga main', value: row.played),
        ),
      ],
    );
  }

  Widget _formSection() {
    final last = lastFinished(_matches, widget.clubName);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Form laga terakhir'),
        if (last.isEmpty)
          const Text('Belum ada laga selesai.')
        else ...[
          Row(
            children: [
              for (final m in last)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FormDot(result: resultFor(m, widget.clubName)!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final m in last)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(m.label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    '${m.homeScore} - ${m.awayScore}',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _nextCard() {
    final next = nextMatch(_matches, widget.clubName, DateTime.now().toUtc());
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.event_outlined),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laga berikutnya',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: context.fz.textMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  next == null
                      ? 'Belum ada jadwal.'
                      : '${next.label}\n${formatDayHeader(next.kickoffUtc)}, ${formatTimeOnly(next.kickoffUtc)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.fz.textMuted),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final info = _info;
    final stadium = _stadium;
    final coach = info?.coachName == null
        ? null
        : '${info!.coachName}${info.coachNationality == null ? '' : ' (${info.coachNationality})'}';
    return AppCard(
      child: Column(
        children: [
          _infoRow('Berdiri', info?.founded?.toString()),
          _infoRow('Stadion', info?.venue ?? stadium?.name),
          _infoRow('Kota', stadium?.city),
          _infoRow('Warna klub', info?.clubColors),
          _infoRow('Pelatih', coach),
          _infoRow('Situs', info?.website),
          if (info == null || (info.coachName == null && info.founded == null))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Data lengkap klub muncul bila FOOTBALL_API_KEY terisi.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.fz.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scorersSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Pencetak gol klub'),
        if (_scorers.isEmpty)
          const Text('Belum ada pemain klub ini di daftar top skor.')
        else
          for (final s in _scorers.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.player, style: theme.textTheme.bodyLarge),
                  ),
                  Text('${s.goals} gol', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
      ],
    );
  }

  Widget _squadSection() {
    final squad = _info?.squad ?? [];
    final theme = Theme.of(context);
    final now = DateTime.now();
    if (squad.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Skuad'),
          Text(
            'Skuad muncul bila FOOTBALL_API_KEY terisi dan datanya tersedia.',
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Skuad (${squad.length} pemain)'),
        for (final group in groupSquad(squad)) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              group.key,
              style: theme.textTheme.titleSmall?.copyWith(
                color: context.fz.accent,
              ),
            ),
          ),
          for (final p in group.value)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    [
                      if (p.nationality.isNotEmpty) p.nationality,
                      if (p.ageOn(now) != null) '${p.ageOn(now)} th',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.fz.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _content() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(),
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
              FadeSlideIn(child: _statsRow()),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(index: 1, child: _formSection()),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(index: 2, child: _nextCard()),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(index: 3, child: _infoCard()),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(index: 4, child: _scorersSection()),
              const SizedBox(height: AppSpacing.xl),
              FadeSlideIn(index: 5, child: _squadSection()),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorState(message: _error!, onRetry: _load);
    } else {
      body = _content();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clubName),
        actions: [
          ValueListenableBuilder<String?>(
            valueListenable: SettingsService.favoriteNotifier,
            builder: (context, favorite, _) {
              final isFavorite = favorite == widget.clubName;
              return IconButton(
                tooltip: isFavorite ? 'Klub favoritmu' : 'Jadikan klub favorit',
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                onPressed: isFavorite ? null : _makeFavorite,
              );
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
