/// Satu pertandingan dari API football-data.org.
class FootballMatch {
  const FootballMatch({
    required this.id,
    required this.kickoffUtc,
    required this.status,
    required this.homeName,
    required this.awayName,
    this.matchday,
    this.homeScore,
    this.awayScore,
    this.homeCrest,
    this.awayCrest,
  });

  final int id;
  final DateTime kickoffUtc;

  /// Mis. SCHEDULED, IN_PLAY, FINISHED, POSTPONED.
  final String status;
  final String homeName;
  final String awayName;
  final int? matchday;
  final int? homeScore;
  final int? awayScore;
  final String? homeCrest;
  final String? awayCrest;

  bool get isFinished => status == 'FINISHED';
  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
  bool get hasScore => homeScore != null && awayScore != null;

  String get label => '$homeName vs $awayName';

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    final home = json['homeTeam'] as Map<String, dynamic>;
    final away = json['awayTeam'] as Map<String, dynamic>;
    final score = json['score'] as Map<String, dynamic>?;
    final fullTime = score?['fullTime'] as Map<String, dynamic>?;

    return FootballMatch(
      id: (json['id'] as num).toInt(),
      kickoffUtc: DateTime.parse(json['utcDate'] as String).toUtc(),
      status: (json['status'] ?? 'SCHEDULED').toString(),
      matchday: (json['matchday'] as num?)?.toInt(),
      homeName: (home['shortName'] ?? home['name'] ?? '?').toString(),
      awayName: (away['shortName'] ?? away['name'] ?? '?').toString(),
      homeScore: (fullTime?['home'] as num?)?.toInt(),
      awayScore: (fullTime?['away'] as num?)?.toInt(),
      homeCrest: home['crest'] as String?,
      awayCrest: away['crest'] as String?,
    );
  }
}
