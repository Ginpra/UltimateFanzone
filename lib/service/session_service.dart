import 'package:shared_preferences/shared_preferences.dart';

/// Akun dan sesi login lokal (SharedPreferences). Tidak ada server; password disimpan
/// apa adanya, cukup untuk latihan.
class SessionService {
  static const _sessionKey = 'session_user';
  static const _accountPrefix = 'account_';
  static const _biometricKey = 'biometric_user';

  /// Daftar akun baru. Mengembalikan pesan error, atau null bila berhasil.
  /// Setelah daftar pengguna belum login; ia harus masuk lewat layar Login.
  Future<String?> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_accountPrefix$username';
    if (prefs.containsKey(key)) return 'Username sudah dipakai';
    await prefs.setString(key, password);
    return null;
  }

  /// Masuk. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_accountPrefix$username');
    if (saved == null || saved != password) {
      return 'Username atau password salah';
    }
    await prefs.setString(_sessionKey, username);
    return null;
  }

  /// Username yang sedang login, atau null bila belum login.
  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  /// Username yang boleh masuk lewat biometrik di HP ini, atau null.
  Future<String?> biometricUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricKey);
  }

  /// Aktifkan masuk biometrik untuk akun [username] (dipanggil dari Profil).
  Future<void> enableBiometric(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_biometricKey, username);
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricKey);
  }

  /// Masuk sebagai [username] tanpa password. Hanya dipanggil setelah
  /// biometrik berhasil diverifikasi.
  Future<void> loginWithBiometric(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, username);
  }
}
