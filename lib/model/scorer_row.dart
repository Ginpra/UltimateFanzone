class ScorerRow {
  const ScorerRow({
    required this.player,
    required this.team,
    required this.goals,
    this.assists,
    this.teamCrest,
  });

  final String player;
  final String team;
  final int goals;
  final int? assists;
  final String? teamCrest;

  factory ScorerRow.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>;
    final team = json['team'] as Map<String, dynamic>;
    return ScorerRow(
      player: (player['name'] ?? '?').toString(),
      team: (team['shortName'] ?? team['name'] ?? '?').toString(),
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt(),
      teamCrest: team['crest'] as String?,
    );
  }
}
