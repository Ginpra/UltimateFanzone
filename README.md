# Ultimate Fanzone

Aplikasi pendamping suporter Liga Inggris (Premier League) yang dibuat dengan
Flutter. Pengguna dapat memantau jadwal, klasemen, dan top skor, menjelajahi 20
klub dan stadionnya di peta, mengumpulkan stempel stadion lewat GPS, memasang
pengingat kickoff, mencatat pengeluaran tandang, menebak skor, serta bertanya
kepada Pundit AI.

Proyek akhir Praktikum Pemrograman Aplikasi Mobile.

| Item                                | Nilai                                    |
| ----------------------------------- | ---------------------------------------- |
| Nama paket Dart                     | `ultimate_fanzone`                       |
| Label aplikasi                      | Ultimate Fanzone                         |
| `applicationId` / namespace Android | `com.smartfootballfan`                   |
| Repositori                          | https://github.com/Ginpra/UltimateFanzone |
| Versi Dart                          | `>=3.2.0 <4.0.0`                         |

## Fitur

| Fitur                  | Keterangan singkat                                                                 |
| ---------------------- | ---------------------------------------------------------------------------------- |
| Login dan daftar       | Akun lokal, opsi masuk dengan sidik jari (biometrik).                              |
| Beranda                | Laga berikutnya, ringkasan klub favorit, pintasan fitur, tiga klub teratas.        |
| Laga                   | Jadwal per hari, klasemen, dan top skor dari football-data.org.                    |
| Klub                   | Direktori 20 klub dengan pencarian, halaman detail, dan klub favorit.              |
| Pundit AI              | Tanya jawab sepak bola dengan Gemini API.                                          |
| Peta Stadion           | Peta OpenStreetMap, posisi pengguna, jarak ke tiap stadion, urut dari terdekat.    |
| Paspor Suporter        | Stempel stadion bila pengguna berada dalam radius 800 m (ada mode demo).           |
| Pengingat laga        | Notifikasi terjadwal sebelum kickoff, menit pengingat dapat diubah.                |
| SOS                    | Mengambil koordinat dan menampilkannya di layar dan notifikasi (tidak dikirim).   |
| Away Day               | Pencatat pengeluaran tandang dan anggaran.                                         |
| Prediksi skor          | Tebak skor laga; skor persis 3 poin, hasil benar 1 poin.                           |
| Catatan laga           | Tambah, ubah, dan hapus catatan pribadi.                                           |
| Refleks Kiper          | Game kecil dengan nyawa dan skor terbaik.                                          |

## Teknologi

| Paket                                      | Kegunaan                                           |
| ------------------------------------------ | -------------------------------------------------- |
| `http`                                     | Memanggil football-data.org dan Gemini API         |
| `hive`, `hive_flutter`                     | Penyimpanan daftar data dan cache API              |
| `shared_preferences`                       | Akun, sesi login, dan pengaturan                   |
| `geolocator`                               | GPS dan perhitungan jarak                          |
| `flutter_map`, `latlong2`                  | Peta OpenStreetMap dan koordinat                   |
| `flutter_local_notifications`, `timezone`  | Notifikasi instan dan terjadwal (Asia/Jakarta)     |
| `local_auth`                               | Masuk dengan sidik jari atau wajah                 |

## Struktur folder

```
lib/
  main.dart        Titik masuk: inisialisasi Hive, notifikasi, cek sesi login
  core/            Tema, warna, format, konfigurasi, aturan game, kunci API
  model/           Bentuk data (FootballMatch, ClubInfo, Expense, Stadium, dll.)
  service/         Logika data: API, penyimpanan lokal, lokasi, notifikasi
  pages/           Halaman (tampilan dan interaksi)
  widgets/         Potongan tampilan yang dipakai ulang
test/
  model_test.dart  Pengujian model dan fungsi format
```

Pola yang dipakai: **Page** (tampilan, `setState`), **Service** (logika dan
akses data), **Model** (bentuk data dengan `fromJson` / `toJson`).

## Penyimpanan data

Semua data tersimpan **lokal di perangkat**, tidak ada server.

| Data                                              | Tempat                                  |
| ------------------------------------------------- | --------------------------------------- |
| Akun, sesi login, pengaturan, klub favorit, skor game | SharedPreferences                   |
| Catatan, tebakan, pengeluaran, stempel (per akun) | Hive, box `local_lists`                 |
| Cache jadwal, klasemen, top skor, klub            | Hive, box `football_cache`              |

Key Hive memuat username (contoh `notes_v1_<username>`), sehingga data tiap
akun terpisah.

## Menjalankan aplikasi

Prasyarat: Flutter SDK terbaru (`pubspec.lock` mensyaratkan Flutter 3.47.0 atau
lebih baru), Android Studio atau VS Code, dan HP Android atau emulator.

```bash
git clone https://github.com/Ginpra/UltimateFanzone.git
cd UltimateFanzone
flutter pub get
```

### Mengisi kunci API

Aplikasi memerlukan dua kunci. Pilih **salah satu** cara berikut.

**Cara 1: `env.json` lalu skrip (Windows PowerShell)**

1. Buat `env.json` di folder proyek (sudah ada di `.gitignore`):

   ```json
   {
     "FOOTBALL_API_KEY": "isi_key_football_data",
     "GEMINI_API_KEY": "isi_key_gemini",
     "GEMINI_MODEL": ""
   }
   ```

2. Jalankan sekali: `.\siapkan_kunci.ps1`. Skrip membuat
   `lib/core/secrets.dart` (juga di `.gitignore`).
3. `flutter run -d <id-perangkat>`

**Cara 2: salin manual**

Salin `lib/core/secrets.example.dart` menjadi `lib/core/secrets.dart`, isi
kuncinya, lalu `flutter run`.

**Cara 3: `--dart-define`** (mengalahkan isi `secrets.dart`)

```bash
flutter run \
  --dart-define=FOOTBALL_API_KEY=ISI_KEY \
  --dart-define=GEMINI_API_KEY=ISI_KEY
```

`GEMINI_MODEL` bersifat opsional. Bila kosong, aplikasi memakai daftar model
bawaan dan mencoba model berikutnya jika satu model tidak ditemukan.

### Mendapatkan kunci

- **football-data.org:** daftar di https://www.football-data.org/client/register,
  lalu uji kuncinya:

  ```bash
  curl -H "X-Auth-Token: KEY_ANDA" https://api.football-data.org/v4/competitions/PL/matches
  ```

- **Gemini:** buat API key melalui Google AI Studio, lalu isi `GEMINI_API_KEY`.

### Bila kunci kosong

- Tanpa `FOOTBALL_API_KEY`: aplikasi memakai **data contoh** dan menampilkan
  banner, bukan jadwal resmi. Info klub, pelatih, dan skuad butuh kunci ini.
- Tanpa `GEMINI_API_KEY`: Pundit AI tidak dapat dipakai.

### Perilaku data jaringan

- Hasil jadwal, klasemen, dan top skor di-cache 15 menit; data klub 24 jam.
- Bila jaringan gagal, data cache terakhir dipakai.
- Paket gratis football-data.org dibatasi jumlah request per menit (cek batas
  terbaru di situs resminya).
- **Jangan commit kunci API.** `env.json` dan `lib/core/secrets.dart` sudah ada
  di `.gitignore`; hanya `secrets.example.dart` yang ikut repositori.

## Izin dan konfigurasi Android

Izin di `android/app/src/main/AndroidManifest.xml`:

| Izin                                  | Dipakai untuk                          |
| ------------------------------------- | -------------------------------------- |
| `INTERNET`                            | Memanggil API                          |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Peta Stadion, Paspor, SOS    |
| `USE_BIOMETRIC`, `USE_FINGERPRINT`    | Masuk dengan sidik jari                |
| `POST_NOTIFICATIONS`                  | Menampilkan notifikasi                 |
| `SCHEDULE_EXACT_ALARM`                | Pengingat tepat waktu                  |
| `RECEIVE_BOOT_COMPLETED`, `VIBRATE`   | Menjadwalkan ulang alarm setelah restart HP, getar |

- `MainActivity` memakai `FlutterFragmentActivity` (syarat `local_auth`).
- `core library desugaring` diaktifkan di `android/app/build.gradle.kts`
  (syarat `flutter_local_notifications`).
- Receiver `ScheduledNotificationReceiver` dan
  `ScheduledNotificationBootReceiver` terdaftar di manifest.

Pada iOS, `Info.plist` memuat deskripsi izin lokasi dan Face ID. Pengujian
utama dilakukan pada Android.

## Pengujian

```bash
flutter analyze
flutter test
```

Uji manual di perangkat sungguhan untuk fitur yang bergantung perangkat: GPS
(Peta, Paspor, SOS), notifikasi terjadwal, dan sidik jari. Emulator sering
bermasalah pada ketiganya. Di emulator, atur lokasi lewat menu titik tiga
(Extended controls), bagian Location. Paspor juga menyediakan **mode demo**
untuk mencoba stempel tanpa berada di stadion.

## Keterbatasan yang diketahui

- Login hanya lokal dan password disimpan apa adanya (cukup untuk latihan,
  belum layak produksi).
- SOS hanya menampilkan lokasi di layar dan notifikasi lokal; tidak mengirimnya
  ke siapa pun.
- Riwayat percakapan Pundit AI tidak disimpan dan hilang saat layar ditutup.
- Data tidak tersinkron antarperangkat karena tidak ada server.

## Tim pengembang

| Nama | NIM |
| Gilang | 124240056 |
| Shofa | 124240058 |                