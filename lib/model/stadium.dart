/// Satu klub Premier League beserta stadionnya (data dari projek partner).
class Stadium {
  const Stadium({
    required this.club,
    required this.tla,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    required this.color,
    required this.aliases,
  });

  final String club;

  /// Kode tiga huruf klub, mis. ARS.
  final String tla;
  final String name;
  final String city;
  final double lat;
  final double lng;

  /// Warna klub dalam format ARGB, mis. 0xFFEF0107.
  final int color;

  /// Nama lain klub (huruf kecil) untuk mencocokkan nama dari API.
  final List<String> aliases;
}

/// Jarak maksimal (meter) dari stadion agar cap stamp lewat GPS diterima.
const double stampRadiusMeters = 800;

/// Daftar 20 klub dan stadionnya. Bergantung musim; cek ulang kalau berganti.
const List<Stadium> stadiums = [
  Stadium(
    club: 'Arsenal',
    tla: 'ARS',
    name: 'Emirates Stadium',
    city: 'London',
    lat: 51.5549,
    lng: -0.1084,
    color: 0xFFEF0107,
    aliases: ['arsenal'],
  ),
  Stadium(
    club: 'Aston Villa',
    tla: 'AVL',
    name: 'Villa Park',
    city: 'Birmingham',
    lat: 52.5092,
    lng: -1.8847,
    color: 0xFF670E36,
    aliases: ['aston villa'],
  ),
  Stadium(
    club: 'Bournemouth',
    tla: 'BOU',
    name: 'Vitality Stadium',
    city: 'Bournemouth',
    lat: 50.7352,
    lng: -1.8384,
    color: 0xFFDA291C,
    aliases: ['bournemouth'],
  ),
  Stadium(
    club: 'Brentford',
    tla: 'BRE',
    name: 'Gtech Community Stadium',
    city: 'London',
    lat: 51.4907,
    lng: -0.2886,
    color: 0xFFE30613,
    aliases: ['brentford'],
  ),
  Stadium(
    club: 'Brighton',
    tla: 'BHA',
    name: 'American Express Stadium',
    city: 'Brighton',
    lat: 50.8616,
    lng: -0.0837,
    color: 0xFF0057B8,
    aliases: ['brighton'],
  ),
  Stadium(
    club: 'Chelsea',
    tla: 'CHE',
    name: 'Stamford Bridge',
    city: 'London',
    lat: 51.4817,
    lng: -0.191,
    color: 0xFF034694,
    aliases: ['chelsea'],
  ),
  Stadium(
    club: 'Coventry',
    tla: 'COV',
    name: 'Coventry Building Society Arena',
    city: 'Coventry',
    lat: 52.4481,
    lng: -1.4957,
    color: 0xFF59CBE8,
    aliases: ['coventry'],
  ),
  Stadium(
    club: 'Crystal Palace',
    tla: 'CRY',
    name: 'Selhurst Park',
    city: 'London',
    lat: 51.3983,
    lng: -0.0856,
    color: 0xFF1B458F,
    aliases: ['crystal palace'],
  ),
  Stadium(
    club: 'Everton',
    tla: 'EVE',
    name: 'Hill Dickinson Stadium',
    city: 'Liverpool',
    lat: 53.4262,
    lng: -3.004,
    color: 0xFF003399,
    aliases: ['everton'],
  ),
  Stadium(
    club: 'Fulham',
    tla: 'FUL',
    name: 'Craven Cottage',
    city: 'London',
    lat: 51.4749,
    lng: -0.2217,
    color: 0xFF1F1F1F,
    aliases: ['fulham'],
  ),
  Stadium(
    club: 'Hull City',
    tla: 'HUL',
    name: 'MKM Stadium',
    city: 'Hull',
    lat: 53.746,
    lng: -0.3675,
    color: 0xFFF5A12D,
    aliases: ['hull'],
  ),
  Stadium(
    club: 'Ipswich',
    tla: 'IPS',
    name: 'Portman Road',
    city: 'Ipswich',
    lat: 52.055,
    lng: 1.1449,
    color: 0xFF3A64A3,
    aliases: ['ipswich'],
  ),
  Stadium(
    club: 'Leeds',
    tla: 'LEE',
    name: 'Elland Road',
    city: 'Leeds',
    lat: 53.7778,
    lng: -1.5722,
    color: 0xFFFFCD00,
    aliases: ['leeds'],
  ),
  Stadium(
    club: 'Liverpool',
    tla: 'LIV',
    name: 'Anfield',
    city: 'Liverpool',
    lat: 53.4308,
    lng: -2.9608,
    color: 0xFFC8102E,
    aliases: ['liverpool'],
  ),
  Stadium(
    club: 'Man City',
    tla: 'MCI',
    name: 'Etihad Stadium',
    city: 'Manchester',
    lat: 53.4831,
    lng: -2.2004,
    color: 0xFF6CABDD,
    aliases: ['manchester city', 'man city'],
  ),
  Stadium(
    club: 'Man United',
    tla: 'MUN',
    name: 'Old Trafford',
    city: 'Manchester',
    lat: 53.4631,
    lng: -2.2913,
    color: 0xFFDA291C,
    aliases: ['manchester united', 'man united'],
  ),
  Stadium(
    club: 'Newcastle',
    tla: 'NEW',
    name: 'St James\' Park',
    city: 'Newcastle',
    lat: 54.9756,
    lng: -1.6217,
    color: 0xFF241F20,
    aliases: ['newcastle'],
  ),
  Stadium(
    club: 'Nottingham Forest',
    tla: 'NOT',
    name: 'City Ground',
    city: 'Nottingham',
    lat: 52.94,
    lng: -1.1328,
    color: 0xFFDD0000,
    aliases: ['nottingham forest', 'nottingham'],
  ),
  Stadium(
    club: 'Sunderland',
    tla: 'SUN',
    name: 'Stadium of Light',
    city: 'Sunderland',
    lat: 54.9146,
    lng: -1.3884,
    color: 0xFFEB172B,
    aliases: ['sunderland'],
  ),
  Stadium(
    club: 'Tottenham',
    tla: 'TOT',
    name: 'Tottenham Hotspur Stadium',
    city: 'London',
    lat: 51.6043,
    lng: -0.0664,
    color: 0xFF132257,
    aliases: ['tottenham', 'spurs'],
  ),
];

/// Mencari klub dari nama yang dipakai API (mis. "Man City", "Spurs").
/// Mengembalikan null bila tidak ada yang cocok.
Stadium? stadiumOfClub(String name) {
  final n = name.toLowerCase().trim();
  if (n.isEmpty) return null;
  for (final s in stadiums) {
    if (s.club.toLowerCase() == n || s.aliases.contains(n)) return s;
  }
  for (final s in stadiums) {
    if (s.aliases.any((a) => n.contains(a) || a.contains(n))) return s;
  }
  return null;
}
