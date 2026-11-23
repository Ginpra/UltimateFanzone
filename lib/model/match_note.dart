/// Satu catatan pribadi tentang sebuah laga (disimpan di Hive sebagai JSON).
class MatchNote {
  const MatchNote({
    required this.id,
    required this.match,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String match;
  final String note;
  final DateTime createdAt;

  MatchNote copyWith({String? match, String? note}) => MatchNote(
    id: id,
    match: match ?? this.match,
    note: note ?? this.note,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'match': match,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MatchNote.fromJson(Map<String, dynamic> json) => MatchNote(
    id: json['id'] as String,
    match: json['match'] as String,
    note: json['note'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
