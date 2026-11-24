/// Aturan Refleks Kiper: waktu menepis mulai 1200 ms, turun 40 ms tiap
/// tangkapan, batas tercepat 500 ms.
const int reflexStartLimitMs = 1200;
const int reflexMinLimitMs = 500;
const int reflexStepMs = 40;
const int reflexStartLives = 3;

/// Batas waktu berikutnya setelah satu tangkapan berhasil.
int nextReflexLimit(int currentMs) {
  final next = currentMs - reflexStepMs;
  return next < reflexMinLimitMs ? reflexMinLimitMs : next;
}

/// Level 1 sampai seterusnya, naik tiap 5 tangkapan.
int reflexLevel(int score) => score ~/ 5 + 1;
