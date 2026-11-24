import 'secrets.dart';

/// Pengaturan aplikasi. Kunci API ada di `secrets.dart` (tidak ikut git),
/// jadi cukup `flutter run -d <id-HP>`. Kalau ada `--dart-define`, nilainya
/// mengalahkan isi secrets.dart.
class AppConfig {
  static const String footballApiKey = String.fromEnvironment(
    'FOOTBALL_API_KEY',
    defaultValue: Secrets.footballApiKey,
  );

  static const String footballBaseUrl = 'https://api.football-data.org/v4';

  /// Tanpa kunci, aplikasi memakai data contoh supaya layar tidak kosong.
  static bool get hasFootballKey => footballApiKey.isNotEmpty;

  /// Kunci Gemini untuk Pundit AI. Kosong = Pundit AI tidak bisa dipakai.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: Secrets.geminiApiKey,
  );

  /// Nama model Gemini (opsional). Kosong = pakai daftar model bawaan.
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: Secrets.geminiModel,
  );

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
