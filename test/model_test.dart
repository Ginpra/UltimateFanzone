import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_fanzone/core/club_stats.dart';
import 'package:ultimate_fanzone/core/crest_registry.dart';
import 'package:ultimate_fanzone/core/format.dart';
import 'package:ultimate_fanzone/core/gemini_parser.dart';
import 'package:ultimate_fanzone/core/reflex_rules.dart';
import 'package:ultimate_fanzone/model/club_info.dart';
import 'package:ultimate_fanzone/model/expense.dart';
import 'package:ultimate_fanzone/model/football_match.dart';
import 'package:ultimate_fanzone/model/match_note.dart';
import 'package:ultimate_fanzone/model/prediction.dart';
import 'package:ultimate_fanzone/model/scorer_row.dart';
import 'package:ultimate_fanzone/model/stadium.dart';
import 'package:ultimate_fanzone/model/stamp.dart';
import 'package:ultimate_fanzone/model/standing_row.dart';

void main() {
  test('MatchNote: toJson lalu fromJson menghasilkan data yang sama', () {
    final created = DateTime(2026, 11, 22, 9, 30);
    final note = MatchNote(
      id: '1',
      match: 'Arsenal vs Chelsea',
      note: 'Gol telat di menit 90',
      createdAt: created,
    );
    final restored = MatchNote.fromJson(note.toJson());
    expect(restored.match, 'Arsenal vs Chelsea');
    expect(restored.note, 'Gol telat di menit 90');
    expect(restored.createdAt, created);
  });

  test('FootballMatch.fromJson membaca format football-data.org', () {
    final match = FootballMatch.fromJson({
      'id': 10,
      'utcDate': '2026-11-22T15:00:00Z',
      'status': 'FINISHED',
      'matchday': 12,
      'homeTeam': {'name': 'Arsenal FC', 'shortName': 'Arsenal'},
      'awayTeam': {'name': 'Chelsea FC', 'shortName': 'Chelsea'},
      'score': {
        'fullTime': {'home': 2, 'away': 1},
      },
    });
    expect(match.homeName, 'Arsenal');
    expect(match.awayName, 'Chelsea');
    expect(match.isFinished, true);
    expect(match.hasScore, true);
    expect(match.homeScore, 2);
  });

  test('FootballMatch.fromJson: laga belum main tidak punya skor', () {
    final match = FootballMatch.fromJson({
      'id': 11,
      'utcDate': '2026-11-29T15:00:00Z',
      'status': 'SCHEDULED',
      'homeTeam': {'name': 'Liverpool FC'},
      'awayTeam': {'name': 'Manchester City FC'},
      'score': {
        'fullTime': {'home': null, 'away': null},
      },
    });
    expect(match.hasScore, false);
    expect(match.isFinished, false);
  });

  test('StandingRow.fromJson membaca satu baris klasemen', () {
    final row = StandingRow.fromJson({
      'position': 1,
      'team': {'name': 'Arsenal FC', 'shortName': 'Arsenal'},
      'playedGames': 10,
      'won': 8,
      'draw': 1,
      'lost': 1,
      'goalDifference': 14,
      'points': 25,
    });
    expect(row.team, 'Arsenal');
    expect(row.points, 25);
    expect(row.goalDiff, 14);
  });

  predictionAndFormatTests();
  stadiumAndStampTests();
  geminiAndReflexTests();
  clubStatsTests();
  homeAndGroupingTests();
  clubInfoTests();
}

void predictionAndFormatTests() {
  FootballMatch finished(int home, int away) => FootballMatch(
    id: 1,
    kickoffUtc: DateTime.utc(2026, 11, 22),
    status: 'FINISHED',
    homeName: 'A',
    awayName: 'B',
    homeScore: home,
    awayScore: away,
  );

  Prediction guess(int home, int away) => Prediction(
    matchId: 1,
    label: 'A vs B',
    kickoffUtc: DateTime.utc(2026, 11, 22),
    home: home,
    away: away,
    createdAt: DateTime(2026, 11, 20),
  );

  test('Prediction: skor persis dapat 3 poin', () {
    expect(guess(2, 1).pointsFor(finished(2, 1)), 3);
  });

  test('Prediction: hasil benar tapi skor beda dapat 1 poin', () {
    expect(guess(3, 0).pointsFor(finished(2, 1)), 1);
    expect(guess(1, 1).pointsFor(finished(0, 0)), 1);
  });

  test('Prediction: hasil salah dapat 0 poin', () {
    expect(guess(0, 2).pointsFor(finished(2, 1)), 0);
  });

  test('Prediction: laga belum selesai belum ada poin', () {
    final scheduled = FootballMatch(
      id: 1,
      kickoffUtc: DateTime.utc(2026, 11, 29),
      status: 'SCHEDULED',
      homeName: 'A',
      awayName: 'B',
    );
    expect(guess(1, 0).pointsFor(scheduled), isNull);
  });

  test('formatRupiah memberi pemisah ribuan', () {
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(950), 'Rp 950');
    expect(formatRupiah(1500000), 'Rp 1.500.000');
  });

  test('Expense dan Prediction: JSON bolak-balik', () {
    final e = Expense(
      id: '9',
      title: 'Tiket',
      category: 'Tiket',
      amount: 250000,
      createdAt: DateTime(2026, 11, 22),
    );
    expect(Expense.fromJson(e.toJson()).amount, 250000);
    final p = guess(2, 2);
    expect(Prediction.fromJson(p.toJson()).home, 2);
  });
}

void stadiumAndStampTests() {
  test('Daftar stadion berisi 20 stadion dengan koordinat valid', () {
    expect(stadiums.length, 20);
    expect(
      stadiums.every((s) => s.lat.abs() <= 90 && s.lng.abs() <= 180),
      true,
    );
  });

  test('formatDistance: meter, kilometer, dan ribuan kilometer', () {
    expect(formatDistance(850), '850 m');
    expect(formatDistance(5432), '5,4 km');
    expect(formatDistance(11234000), '11.234 km');
  });

  test('Stamp: JSON bolak-balik', () {
    final stamp = Stamp(
      stadium: 'Anfield',
      club: 'Liverpool',
      stampedAt: DateTime(2026, 11, 22),
      byGps: false,
    );
    final restored = Stamp.fromJson(stamp.toJson());
    expect(restored.stadium, 'Anfield');
    expect(restored.byGps, false);
  });
}

void geminiAndReflexTests() {
  test('parseGeminiText menggabungkan teks dan membuang bagian thought', () {
    final body = {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'Halo '},
              {'thought': true, 'text': 'rahasia'},
              {'text': 'dunia'},
            ],
          },
        },
      ],
    };
    expect(parseGeminiText(body), 'Halo dunia');
  });

  test('parseGeminiText mengembalikan null bila tidak ada jawaban', () {
    expect(parseGeminiText({'candidates': []}), isNull);
    expect(
      parseGeminiText({
        'error': {'message': 'x'},
      }),
      isNull,
    );
    expect(parseGeminiText('bukan map'), isNull);
  });

  test('Refleks: batas waktu turun 40 ms dan berhenti di 500 ms', () {
    expect(nextReflexLimit(1200), 1160);
    expect(nextReflexLimit(520), 500);
    expect(nextReflexLimit(500), 500);
  });

  test('Refleks: level naik tiap 5 tangkapan', () {
    expect(reflexLevel(0), 1);
    expect(reflexLevel(4), 1);
    expect(reflexLevel(5), 2);
  });
}

void clubStatsTests() {
  FootballMatch match(
    int id,
    String home,
    String away,
    int? h,
    int? a, {
    String status = 'FINISHED',
    int day = 1,
  }) {
    return FootballMatch(
      id: id,
      kickoffUtc: DateTime.utc(2026, 11, day),
      status: status,
      homeName: home,
      awayName: away,
      homeScore: h,
      awayScore: a,
    );
  }

  test('resultFor: menang, seri, kalah dari sudut pandang klub', () {
    expect(resultFor(match(1, 'Arsenal', 'Chelsea', 2, 1), 'Arsenal'), 'W');
    expect(resultFor(match(1, 'Arsenal', 'Chelsea', 2, 1), 'Chelsea'), 'L');
    expect(resultFor(match(2, 'Arsenal', 'Chelsea', 1, 1), 'Chelsea'), 'D');
    expect(resultFor(match(3, 'Spurs', 'Chelsea', 1, 1), 'Arsenal'), isNull);
    expect(
      resultFor(
        match(4, 'Arsenal', 'Chelsea', null, null, status: 'SCHEDULED'),
        'Arsenal',
      ),
      isNull,
    );
  });

  test('lastFinished: terbaru dulu, hanya laga selesai klub itu', () {
    final all = [
      match(1, 'Arsenal', 'Chelsea', 2, 1, day: 1),
      match(2, 'Spurs', 'Arsenal', 0, 0, day: 8),
      match(3, 'Liverpool', 'Chelsea', 3, 0, day: 9),
      match(4, 'Arsenal', 'Everton', null, null, status: 'SCHEDULED', day: 20),
    ];
    final last = lastFinished(all, 'Arsenal');
    expect(last.map((m) => m.id).toList(), [2, 1]);
    expect(lastFinished(all, 'Arsenal', count: 1).length, 1);
  });

  test('nextMatch: laga mendatang terdekat milik klub', () {
    final all = [
      match(1, 'Arsenal', 'Chelsea', null, null, status: 'SCHEDULED', day: 25),
      match(2, 'Arsenal', 'Everton', null, null, status: 'SCHEDULED', day: 22),
      match(3, 'Arsenal', 'Spurs', 1, 0, day: 5),
    ];
    final next = nextMatch(all, 'Arsenal', DateTime.utc(2026, 11, 20));
    expect(next?.id, 2);
    expect(nextMatch(all, 'Liverpool', DateTime.utc(2026, 11, 20)), isNull);
  });
}

void homeAndGroupingTests() {
  FootballMatch match(int id, DateTime utc, {String status = 'SCHEDULED'}) {
    return FootballMatch(
      id: id,
      kickoffUtc: utc,
      status: status,
      homeName: 'A',
      awayName: 'B',
    );
  }

  test('stadiumOfClub mengenali nama klub dari API', () {
    expect(stadiumOfClub('Man City')?.tla, 'MCI');
    expect(stadiumOfClub('Arsenal')?.tla, 'ARS');
    expect(stadiumOfClub('Klub Tidak Ada'), isNull);
    expect(stadiumOfClub(''), isNull);
  });

  test('formatCountdown: jam, hari, dan waktu habis', () {
    expect(
      formatCountdown(const Duration(hours: 2, minutes: 14, seconds: 9)),
      '02:14:09',
    );
    expect(
      formatCountdown(const Duration(days: 3, hours: 4, minutes: 10)),
      '3 hari 04:10',
    );
    expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
  });

  test('formatDayHeader memakai nama hari dan bulan Indonesia', () {
    expect(formatDayHeader(DateTime(2026, 11, 22)), 'Minggu, 22 Nov');
    expect(formatDayHeader(DateTime(2026, 11, 21)), 'Sabtu, 21 Nov');
  });

  test('nextAnyMatch: laga mendatang terdekat dari semua klub', () {
    final now = DateTime.utc(2026, 11, 20);
    final all = [
      match(1, DateTime.utc(2026, 11, 25)),
      match(2, DateTime.utc(2026, 11, 22)),
      match(3, DateTime.utc(2026, 11, 10), status: 'FINISHED'),
    ];
    expect(nextAnyMatch(all, now)?.id, 2);
    expect(nextAnyMatch([all[2]], now), isNull);
  });

  test('groupByDay: dikelompokkan per hari dan urut jam', () {
    final groups = groupByDay([
      match(1, DateTime(2026, 11, 22, 15).toUtc()),
      match(2, DateTime(2026, 11, 22, 12).toUtc()),
      match(3, DateTime(2026, 11, 21, 20).toUtc()),
    ]);
    expect(groups.length, 2);
    expect(groups.first.key, DateTime(2026, 11, 21));
    expect(groups.last.value.map((m) => m.id).toList(), [2, 1]);
  });
}

void clubInfoTests() {
  final arsenal = {
    'name': 'Arsenal FC',
    'shortName': 'Arsenal',
    'tla': 'ARS',
    'crest': 'https://crests.football-data.org/57.png',
    'founded': 1886,
    'venue': 'Emirates Stadium',
    'coach': {'name': 'Mikel Arteta', 'nationality': 'Spain'},
    'squad': [
      {
        'name': 'David Raya',
        'position': 'Goalkeeper',
        'dateOfBirth': '1995-09-15',
        'nationality': 'Spain',
      },
      {
        'name': 'William Saliba',
        'position': 'Centre-Back',
        'dateOfBirth': '2001-03-24',
        'nationality': 'France',
      },
      {
        'name': 'Declan Rice',
        'position': 'Central Midfield',
        'dateOfBirth': '1999-01-14',
        'nationality': 'England',
      },
      {
        'name': 'Bukayo Saka',
        'position': 'Right Winger',
        'dateOfBirth': '2001-09-05',
        'nationality': 'England',
      },
      {
        'name': 'Tanpa Posisi',
        'position': null,
        'dateOfBirth': null,
        'nationality': null,
      },
    ],
  };

  test('ClubInfo.fromJson membaca profil, pelatih, dan skuad', () {
    final club = ClubInfo.fromJson(arsenal);
    expect(club.shortName, 'Arsenal');
    expect(club.founded, 1886);
    expect(club.coachName, 'Mikel Arteta');
    expect(club.squad.length, 5);
  });

  test('ClubInfo.fromJson tahan data minimal tanpa skuad', () {
    final club = ClubInfo.fromJson({'name': 'X FC', 'tla': 'XXX'});
    expect(club.shortName, 'X FC');
    expect(club.squad, isEmpty);
    expect(club.coachName, isNull);
  });

  test('groupSquad: kelompok berurutan dan kelompok kosong dibuang', () {
    final groups = groupSquad(ClubInfo.fromJson(arsenal).squad);
    expect(groups.map((g) => g.key).toList(), [
      'Kiper',
      'Bek',
      'Gelandang',
      'Penyerang',
      'Lainnya',
    ]);
    final onlyKeepers = groupSquad([
      const Player(name: 'A', position: 'Goalkeeper', nationality: ''),
    ]);
    expect(onlyKeepers.map((g) => g.key).toList(), ['Kiper']);
  });

  test('Player.ageOn menghitung usia sebelum dan sesudah ulang tahun', () {
    final raya = ClubInfo.fromJson(arsenal).squad.first;
    expect(raya.ageOn(DateTime(2026, 11, 22)), 31);
    expect(raya.ageOn(DateTime(2026, 9, 14)), 30);
    expect(ClubInfo.fromJson(arsenal).squad.last.ageOn(DateTime(2026)), isNull);
  });

  test('Logo klub dibaca dari respons API dan disimpan di CrestRegistry', () {
    final match = FootballMatch.fromJson({
      'id': 1,
      'utcDate': '2026-11-22T15:00:00Z',
      'status': 'SCHEDULED',
      'homeTeam': {'name': 'A', 'crest': 'https://x/1.png'},
      'awayTeam': {'name': 'B'},
      'score': {
        'fullTime': {'home': null, 'away': null},
      },
    });
    expect(match.homeCrest, 'https://x/1.png');
    expect(match.awayCrest, isNull);
    expect(
      ScorerRow.fromJson({
        'player': {'name': 'P'},
        'team': {'name': 'A', 'crest': 'c2'},
        'goals': 1,
      }).teamCrest,
      'c2',
    );

    CrestRegistry.register('Arsenal', 'u1');
    CrestRegistry.register('Chelsea', '');
    CrestRegistry.register('Spurs', null);
    expect(CrestRegistry.urlFor('Arsenal'), 'u1');
    expect(CrestRegistry.urlFor('Chelsea'), isNull);
    expect(CrestRegistry.urlFor('Spurs'), isNull);
  });
}
