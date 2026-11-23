import '../model/football_match.dart';

/// Hitungan statistik satu klub dari daftar laga (tanpa tampilan, mudah diuji).

bool involvesClub(FootballMatch match, String club) =>
    match.homeName == club || match.awayName == club;

/// 'W' menang, 'D' seri, 'L' kalah, dari sudut pandang [club].
/// Null bila laga bukan milik klub itu atau skornya belum ada.
String? resultFor(FootballMatch match, String club) {
  if (!involvesClub(match, club) || !match.hasScore) return null;
  final isHome = match.homeName == club;
  final own = isHome ? match.homeScore! : match.awayScore!;
  final other = isHome ? match.awayScore! : match.homeScore!;
  if (own > other) return 'W';
  if (own < other) return 'L';
  return 'D';
}

/// Laga selesai milik [club], dari yang terbaru, paling banyak [count].
List<FootballMatch> lastFinished(
  List<FootballMatch> all,
  String club, {
  int count = 5,
}) {
  final list =
      all
          .where((m) => involvesClub(m, club) && m.isFinished && m.hasScore)
          .toList()
        ..sort((a, b) => b.kickoffUtc.compareTo(a.kickoffUtc));
  return list.take(count).toList();
}

/// Laga berikutnya milik [club] yang belum selesai dan masih akan datang.
FootballMatch? nextMatch(
  List<FootballMatch> all,
  String club,
  DateTime nowUtc,
) {
  final list =
      all
          .where(
            (m) =>
                involvesClub(m, club) &&
                !m.isFinished &&
                m.kickoffUtc.isAfter(nowUtc),
          )
          .toList()
        ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));
  return list.isEmpty ? null : list.first;
}

/// Laga mendatang terdekat dari semua klub (untuk pengguna tanpa klub favorit).
FootballMatch? nextAnyMatch(List<FootballMatch> all, DateTime nowUtc) {
  final list =
      all.where((m) => !m.isFinished && m.kickoffUtc.isAfter(nowUtc)).toList()
        ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));
  return list.isEmpty ? null : list.first;
}

/// Mengelompokkan laga per hari (jam lokal), urut dari hari terawal.
/// Tiap kelompok berisi laga hari itu, urut jam kickoff.
List<MapEntry<DateTime, List<FootballMatch>>> groupByDay(
  List<FootballMatch> matches,
) {
  final groups = <DateTime, List<FootballMatch>>{};
  for (final m in matches) {
    final local = m.kickoffUtc.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    groups.putIfAbsent(day, () => []).add(m);
  }
  final days = groups.keys.toList()..sort();
  return [
    for (final day in days)
      MapEntry(
        day,
        groups[day]!..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc)),
      ),
  ];
}
