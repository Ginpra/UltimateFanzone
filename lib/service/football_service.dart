import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../model/football_match.dart';
import '../model/scorer_row.dart';
import '../model/standing_row.dart';

/// Asal data yang ditampilkan.
enum DataSource { network, cache, sample }

/// Hasil pengambilan data beserta asalnya (untuk banner di layar).
class FootballData<T> {
  const FootballData(this.items, this.source);

  final List<T> items;
  final DataSource source;
}

/// Error yang pesannya aman ditampilkan ke pengguna.
class FootballException implements Exception {
  const FootballException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Mengambil jadwal dan klasemen Premier League lewat HTTP (Modul V).
///
/// Urutan: cache Hive yang masih baru (15 menit), lalu internet, lalu cache
/// lama bila internet gagal. Tanpa kunci API dipakai data contoh.
class FootballService {
  static const _boxName = 'football_cache';
  static const _freshFor = Duration(minutes: 15);

  Future<Box<String>> _openBox() {
    if (Hive.isBoxOpen(_boxName)) {
      return Future.value(Hive.box<String>(_boxName));
    }
    return Hive.openBox<String>(_boxName);
  }

  Future<FootballData<FootballMatch>> getMatches({bool refresh = false}) async {
    final result = await _fetchJson(
      '/competitions/PL/matches',
      'matches',
      refresh,
    );
    if (result == null) {
      return FootballData(_sampleMatches(), DataSource.sample);
    }
    final list = result.json['matches'] as List<dynamic>? ?? [];
    final items = list
        .map((e) => FootballMatch.fromJson(e as Map<String, dynamic>))
        .toList();
    return FootballData(
      items,
      result.fromCache ? DataSource.cache : DataSource.network,
    );
  }

  Future<FootballData<StandingRow>> getStandings({bool refresh = false}) async {
    final result = await _fetchJson(
      '/competitions/PL/standings',
      'standings',
      refresh,
    );
    if (result == null) {
      return FootballData(_sampleStandings(), DataSource.sample);
    }
    final standings = result.json['standings'] as List<dynamic>? ?? [];
    if (standings.isEmpty) return const FootballData([], DataSource.network);
    // API memberi tabel TOTAL, HOME, AWAY; kita pakai TOTAL.
    final groups = standings.map((e) => e as Map<String, dynamic>).toList();
    final total = groups.firstWhere(
      (g) => g['type'] == 'TOTAL',
      orElse: () => groups.first,
    );
    final table = total['table'] as List<dynamic>? ?? [];
    final items = table
        .map((e) => StandingRow.fromJson(e as Map<String, dynamic>))
        .toList();
    return FootballData(
      items,
      result.fromCache ? DataSource.cache : DataSource.network,
    );
  }

  Future<FootballData<ScorerRow>> getScorers({bool refresh = false}) async {
    final result = await _fetchJson(
      '/competitions/PL/scorers',
      'scorers',
      refresh,
    );
    if (result == null) {
      return FootballData(_sampleScorers(), DataSource.sample);
    }
    final list = result.json['scorers'] as List<dynamic>? ?? [];
    final items = list
        .map((e) => ScorerRow.fromJson(e as Map<String, dynamic>))
        .toList();
    return FootballData(
      items,
      result.fromCache ? DataSource.cache : DataSource.network,
    );
  }

  /// Mengembalikan null bila tidak ada kunci API (pakai data contoh).
  Future<_Payload?> _fetchJson(
    String path,
    String cacheKey,
    bool refresh,
  ) async {
    final box = await _openBox();
    final cachedBody = box.get(cacheKey);
    final cachedAt = DateTime.tryParse(box.get('${cacheKey}_at') ?? '');

    final isFresh =
        cachedBody != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _freshFor;
    if (isFresh && !refresh) return _Payload(_decode(cachedBody), true);

    if (!AppConfig.hasFootballKey) return null;

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${AppConfig.footballBaseUrl}$path'),
            headers: {'X-Auth-Token': AppConfig.footballApiKey},
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (cachedBody != null) return _Payload(_decode(cachedBody), true);
      throw const FootballException(
        'Tidak ada koneksi internet dan belum ada data tersimpan.',
      );
    }

    if (response.statusCode != 200) {
      if (cachedBody != null) return _Payload(_decode(cachedBody), true);
      throw FootballException(_messageForStatus(response.statusCode));
    }

    final json = _decode(response.body);
    await box.put(cacheKey, response.body);
    await box.put('${cacheKey}_at', DateTime.now().toIso8601String());
    return _Payload(json, false);
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw const FootballException('Data dari server tidak terbaca.');
    }
  }

  String _messageForStatus(int code) {
    if (code == 401 || code == 403) {
      return 'Kunci API ditolak. Periksa FOOTBALL_API_KEY di env.json.';
    }
    if (code == 429) {
      return 'Batas permintaan API tercapai. Coba lagi sebentar lagi.';
    }
    return 'Server bermasalah (kode $code).';
  }

  List<FootballMatch> _sampleMatches() {
    final now = DateTime.now().toUtc();
    return [
      FootballMatch(
        id: 1,
        kickoffUtc: now.add(const Duration(days: 1)),
        status: 'SCHEDULED',
        homeName: 'Arsenal',
        awayName: 'Chelsea',
      ),
      FootballMatch(
        id: 2,
        kickoffUtc: now.add(const Duration(days: 2)),
        status: 'SCHEDULED',
        homeName: 'Liverpool',
        awayName: 'Man City',
      ),
      FootballMatch(
        id: 3,
        kickoffUtc: now.subtract(const Duration(days: 3)),
        status: 'FINISHED',
        homeName: 'Spurs',
        awayName: 'Newcastle',
        homeScore: 2,
        awayScore: 1,
      ),
    ];
  }

  List<StandingRow> _sampleStandings() {
    const teams = [
      ['Arsenal', 25, 14],
      ['Man City', 23, 11],
      ['Liverpool', 22, 9],
      ['Chelsea', 19, 6],
      ['Spurs', 17, 3],
      ['Newcastle', 15, 1],
    ];
    return [
      for (var i = 0; i < teams.length; i++)
        StandingRow(
          position: i + 1,
          team: teams[i][0] as String,
          played: 10,
          won: 0,
          draw: 0,
          lost: 0,
          goalDiff: teams[i][2] as int,
          points: teams[i][1] as int,
        ),
    ];
  }

  List<ScorerRow> _sampleScorers() {
    return const [
      ScorerRow(
        player: 'Pemain Contoh A',
        team: 'Man City',
        goals: 9,
        assists: 2,
      ),
      ScorerRow(
        player: 'Pemain Contoh B',
        team: 'Arsenal',
        goals: 7,
        assists: 4,
      ),
      ScorerRow(player: 'Pemain Contoh C', team: 'Liverpool', goals: 6),
    ];
  }
}

class _Payload {
  const _Payload(this.json, this.fromCache);

  final Map<String, dynamic> json;
  final bool fromCache;
}
