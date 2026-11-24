class Player {
  const Player({
    required this.name,
    required this.position,
    required this.nationality,
    this.birthDate,
  });

  final String name;

  /// Posisi mentah dari API, mis. "Goalkeeper" atau "Centre-Back".
  final String position;
  final String nationality;
  final DateTime? birthDate;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: (json['name'] ?? '?').toString(),
    position: (json['position'] ?? '').toString(),
    nationality: (json['nationality'] ?? '').toString(),
    birthDate: DateTime.tryParse((json['dateOfBirth'] ?? '').toString()),
  );

  /// Usia pada tanggal [now], atau null bila tanggal lahir tidak ada.
  int? ageOn(DateTime now) {
    final b = birthDate;
    if (b == null) return null;
    var age = now.year - b.year;
    final hadBirthday =
        now.month > b.month || (now.month == b.month && now.day >= b.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  /// Kelompok posisi dalam bahasa Indonesia untuk menyusun daftar skuad.
  String get positionGroup {
    final p = position.toLowerCase();
    if (p.contains('goalkeeper')) return 'Kiper';
    if (p.contains('back') || p.contains('defen')) return 'Bek';
    if (p.contains('midfield')) return 'Gelandang';
    if (p.contains('wing') ||
        p.contains('forward') ||
        p.contains('striker') ||
        p.contains('offence')) {
      return 'Penyerang';
    }
    return 'Lainnya';
  }
}

/// Urutan kelompok posisi di layar skuad.
const squadGroupOrder = ['Kiper', 'Bek', 'Gelandang', 'Penyerang', 'Lainnya'];

/// Mengelompokkan skuad per posisi menurut [squadGroupOrder]; kelompok kosong dibuang.
List<MapEntry<String, List<Player>>> groupSquad(List<Player> squad) {
  return [
    for (final group in squadGroupOrder)
      if (squad.any((p) => p.positionGroup == group))
        MapEntry(group, squad.where((p) => p.positionGroup == group).toList()),
  ];
}

/// Profil klub dari endpoint daftar tim football-data.org.
class ClubInfo {
  const ClubInfo({
    required this.name,
    required this.shortName,
    required this.tla,
    this.crest,
    this.founded,
    this.venue,
    this.clubColors,
    this.website,
    this.coachName,
    this.coachNationality,
    this.squad = const [],
  });

  final String name;
  final String shortName;
  final String tla;
  final String? crest;
  final int? founded;
  final String? venue;

  /// Teks warna klub dari API, mis. "Red / White".
  final String? clubColors;
  final String? website;
  final String? coachName;
  final String? coachNationality;
  final List<Player> squad;

  factory ClubInfo.fromJson(Map<String, dynamic> json) {
    final coach = json['coach'] as Map<String, dynamic>?;
    final squad = json['squad'] as List<dynamic>? ?? [];
    return ClubInfo(
      name: (json['name'] ?? '?').toString(),
      shortName: (json['shortName'] ?? json['name'] ?? '?').toString(),
      tla: (json['tla'] ?? '').toString(),
      crest: json['crest'] as String?,
      founded: (json['founded'] as num?)?.toInt(),
      venue: json['venue'] as String?,
      clubColors: json['clubColors'] as String?,
      website: json['website'] as String?,
      coachName: coach?['name'] as String?,
      coachNationality: coach?['nationality'] as String?,
      squad: squad
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
