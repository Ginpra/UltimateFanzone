/// Satu stempel di Paspor Suporter.
class Stamp {
  const Stamp({
    required this.stadium,
    required this.club,
    required this.stampedAt,
    required this.byGps,
  });

  final String stadium;
  final String club;
  final DateTime stampedAt;

  /// true bila dicap lewat GPS, false bila lewat mode demo.
  final bool byGps;

  Map<String, dynamic> toJson() => {
    'stadium': stadium,
    'club': club,
    'stampedAt': stampedAt.toIso8601String(),
    'byGps': byGps,
  };

  factory Stamp.fromJson(Map<String, dynamic> json) => Stamp(
    stadium: json['stadium'] as String,
    club: json['club'] as String,
    stampedAt: DateTime.parse(json['stampedAt'] as String),
    byGps: json['byGps'] as bool? ?? false,
  );
}
