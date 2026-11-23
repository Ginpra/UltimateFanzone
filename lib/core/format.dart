/// Fungsi format kecil yang dipakai beberapa layar.
String twoDigits(int n) => n.toString().padLeft(2, '0');

/// Contoh: 15:30 (jam lokal HP).
String formatTimeOnly(DateTime date) {
  final d = date.toLocal();
  return '${twoDigits(d.hour)}:${twoDigits(d.minute)}';
}

/// Contoh: 22/11/2026 15:30 (jam lokal HP).
String formatDateTime(DateTime date) {
  final d = date.toLocal();
  return '${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} '
      '${twoDigits(d.hour)}:${twoDigits(d.minute)}';
}

/// Contoh: 1500000 menjadi "1.500.000".
String groupThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buffer';
}

/// Contoh: 1500000 menjadi "Rp 1.500.000".
String formatRupiah(int amount) => 'Rp ${groupThousands(amount)}';

/// Contoh: 850 menjadi "850 m", 5432 menjadi "5,4 km", 11234000 menjadi "11.234 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  if (km >= 100) return '${groupThousands(km.round())} km';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Contoh: "Sabtu, 22 Nov" (jam lokal HP).
String formatDayHeader(DateTime date) {
  final d = date.toLocal();
  return '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';
}

/// Contoh: 2 jam 14 menit 9 detik menjadi "02:14:09". Lebih dari 24 jam
/// menjadi "3 hari 04:10". Nol atau negatif menjadi "00:00:00".
String formatCountdown(Duration remaining) {
  if (remaining <= Duration.zero) return '00:00:00';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;
  if (hours >= 24) {
    return '${remaining.inDays} hari ${twoDigits(hours % 24)}:${twoDigits(minutes)}';
  }
  return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
}
