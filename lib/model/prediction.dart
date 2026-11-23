import 'football_match.dart';

/// Tebakan skor pengguna untuk satu laga.
class Prediction {
  const Prediction({
    required this.matchId,
    required this.label,
    required this.kickoffUtc,
    required this.home,
    required this.away,
    required this.createdAt,
  });

  final int matchId;

  /// Mis. "Arsenal vs Chelsea".
  final String label;
  final DateTime kickoffUtc;
  final int home;
  final int away;
  final DateTime createdAt;

  /// Poin tebakan ini terhadap hasil laga: skor persis 3 poin, hasil
  /// (menang/seri/kalah) benar 1 poin, selain itu 0. Bernilai null bila laga
  /// belum selesai atau skornya belum ada.
  int? pointsFor(FootballMatch match) {
    if (!match.isFinished || !match.hasScore) return null;
    final realHome = match.homeScore!;
    final realAway = match.awayScore!;
    if (home == realHome && away == realAway) return 3;
    if ((home - away).sign == (realHome - realAway).sign) return 1;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'label': label,
    'kickoffUtc': kickoffUtc.toIso8601String(),
    'home': home,
    'away': away,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    matchId: (json['matchId'] as num).toInt(),
    label: json['label'] as String,
    kickoffUtc: DateTime.parse(json['kickoffUtc'] as String),
    home: (json['home'] as num).toInt(),
    away: (json['away'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
