import 'package:geolocator/geolocator.dart';

import '../model/stadium.dart';

/// Error lokasi yang pesannya aman ditampilkan ke pengguna.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lokasi pengguna (Modul VII LBS): cek GPS, izin, lalu ambil posisi.
class LocationService {
  Future<Position> getCurrentPosition() async {
    // 1. GPS aktif?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('GPS tidak aktif. Nyalakan lokasi di HP.');
    }

    // 2. Izin lokasi
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi diblokir. Aktifkan di pengaturan aplikasi.',
      );
    }

    // 3. Ambil posisi
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw const LocationException('Gagal mendapatkan lokasi. Coba lagi.');
    }
  }

  /// Jarak (meter) dari [position] ke [stadium].
  double distanceTo(Position position, Stadium stadium) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      stadium.lat,
      stadium.lng,
    );
  }
}
