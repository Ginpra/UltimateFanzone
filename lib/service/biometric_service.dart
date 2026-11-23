import 'package:local_auth/local_auth.dart';

/// Sidik jari atau wajah lewat paket `local_auth`.
/// Semua kegagalan (tidak ada sensor, dibatalkan, terkunci) menjadi `false`,
/// jadi layar cukup menampilkan pesan umum.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// true bila HP punya sensor biometrik yang sudah terdaftar.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Meminta pengguna memverifikasi diri. true bila berhasil.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
