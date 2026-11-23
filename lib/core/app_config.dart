/// Pengaturan aplikasi. Kunci API dibaca dari `env.json` lewat perintah
/// `flutter run --dart-define-from-file=env.json` (kunci tidak ditulis di kode).
class AppConfig {
  static const String footballApiKey = String.fromEnvironment(
    'FOOTBALL_API_KEY',
  );

  static const String footballBaseUrl = 'https://api.football-data.org/v4';

  /// Tanpa kunci, aplikasi memakai data contoh supaya layar tidak kosong.
  static bool get hasFootballKey => footballApiKey.isNotEmpty;

  /// Kunci Gemini untuk Pundit AI. Kosong = Pundit AI tidak bisa dipakai.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Nama model Gemini (opsional). Kosong = pakai daftar model bawaan.
  static const String geminiModel = String.fromEnvironment('GEMINI_MODEL');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
