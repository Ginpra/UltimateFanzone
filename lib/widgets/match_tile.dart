import 'package:flutter/material.dart';

import '../core/app_tokens.dart';
import '../core/format.dart';
import '../model/football_match.dart';
import 'app_card.dart';
import 'club_crest.dart';
import 'pill_badge.dart';
import 'pulse_dot.dart';

/// Kartu satu pertandingan ala papan skor: lencana dan nama klub di kiri dan
/// kanan, skor (atau "vs") di tengah dalam blok. Blok skor emas hanya muncul
/// bila skor sudah ada. [highlight] memberi bingkai pada laga klub favorit.
class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, this.highlight = false});

  final FootballMatch match;
  final bool highlight;

  String _statusText() {
    if (match.isFinished) return 'Selesai';
    if (match.isLive) return 'Sedang main';
    if (match.status == 'POSTPONED') return 'Ditunda';
    if (match.status == 'CANCELLED') return 'Dibatalkan';
    return 'Dijadwalkan';
  }

  Widget _team(BuildContext context, String name) {
    return Expanded(
      child: Column(
        children: [
          ClubCrest(name: name, size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fz = context.fz;
    final scoreText = match.hasScore
        ? '${match.homeScore} - ${match.awayScore}'
        : formatTimeOnly(match.kickoffUtc);

    final tile = AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _team(context, match.homeName),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 72),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: match.hasScore ? fz.accent : fz.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    scoreText,
                    style: textTheme.titleLarge?.copyWith(
                      color: match.hasScore ? fz.onAccent : scheme.onSurface,
                    ),
                  ),
                ),
              ),
              _team(context, match.awayName),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (match.isLive) ...[
                const PulseDot(),
                const SizedBox(width: AppSpacing.sm),
              ],
              PillBadge(
                label: _statusText(),
                tone: match.isLive
                    ? PillTone.accent
                    : (match.isFinished ? PillTone.neutral : PillTone.success),
              ),
            ],
          ),
        ],
      ),
    );

    if (!highlight) return tile;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: tile,
    );
  }
}
