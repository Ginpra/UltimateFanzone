/// Aturan game Refleks Kiper (tanpa tampilan, mudah diuji).
///
/// Waktu untuk menepis bola dimulai 1200 ms dan makin cepat 40 ms tiap
/// tangkapan, sampai batas tercepat 500 ms.
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
