/// Satu baris klasemen.
class StandingRow {
  const StandingRow({
    required this.position,
    required this.team,
    required this.played,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalDiff,
    required this.points,
  });

  final int position;
  final String team;
  final int played;
  final int won;
  final int draw;
  final int lost;
  final int goalDiff;
  final int points;

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>;
    return StandingRow(
      position: (json['position'] as num).toInt(),
      team: (team['shortName'] ?? team['name'] ?? '?').toString(),
      played: (json['playedGames'] as num?)?.toInt() ?? 0,
      won: (json['won'] as num?)?.toInt() ?? 0,
      draw: (json['draw'] as num?)?.toInt() ?? 0,
      lost: (json['lost'] as num?)?.toInt() ?? 0,
      goalDiff: (json['goalDifference'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }
}
