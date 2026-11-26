import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/app_settings.dart';

/// Pengaturan ringan di SharedPreferences (Modul VI): nama panggilan,
/// urutan catatan, klub favorit, anggaran Away Day, dan pengaturan pengingat.
class SettingsService {
  /// Mode tema aktif agar seluruh aplikasi dapat bereaksi saat pilihan berubah.
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.dark,
  );

  /// Klub favorit saat ini. Dibagikan ke semua layar lewat ValueNotifier
  /// supaya Beranda dan Profil ikut berubah begitu klub dipilih di tab Laga.
  static final ValueNotifier<String?> favoriteNotifier = ValueNotifier(null);

  static const _nicknameKey = 'supporter_nickname';
  static const _newestFirstKey = 'notes_newest_first';
  static const _darkThemeKey = 'dark_theme';
  static const _favoriteKey = 'favorite_club';
  static const _budgetKey = 'away_budget';
  static const _reflexBestKey = 'reflex_best';
  static const _reminderIdsKey = 'reminder_match_ids';
  static const _reminderMinutesKey = 'reminder_minutes';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      nickname: prefs.getString(_nicknameKey) ?? '',
      newestFirst: prefs.getBool(_newestFirstKey) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, settings.nickname);
    await prefs.setBool(_newestFirstKey, settings.newestFirst);
  }

  /// Mode tema tersimpan; default tetap gelap agar sesuai perilaku sebelumnya.
  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = (prefs.getBool(_darkThemeKey) ?? true)
        ? ThemeMode.dark
        : ThemeMode.light;
    themeModeNotifier.value = mode;
    return mode;
  }

  Future<void> saveDarkTheme(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkThemeKey, enabled);
    themeModeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  /// Nama klub favorit, atau null bila belum dipilih.
  Future<String?> loadFavoriteClub() async {
    final prefs = await SharedPreferences.getInstance();
    final club = prefs.getString(_favoriteKey);
    favoriteNotifier.value = club;
    return club;
  }

  Future<void> saveFavoriteClub(String club) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteKey, club);
    favoriteNotifier.value = club;
  }

  /// Anggaran Away Day dalam Rupiah; 0 berarti belum diatur.
  Future<int> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_budgetKey) ?? 0;
  }

  Future<void> saveBudget(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_budgetKey, amount);
  }

  /// Id laga yang pengingatnya sedang aktif.
  Future<List<int>> loadReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_reminderIdsKey) ?? [];
    return raw.map(int.tryParse).whereType<int>().toList();
  }

  Future<void> saveReminderIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_reminderIdsKey, ids.map((i) => '$i').toList());
  }

  /// Berapa menit sebelum kickoff pengingat dibunyikan (default 30).
  Future<int> loadReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderMinutesKey) ?? 30;
  }

  Future<void> saveReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderMinutesKey, minutes);
  }

  /// Skor terbaik game Refleks Kiper (per HP).
  Future<int> loadBestReflex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reflexBestKey) ?? 0;
  }

  Future<void> saveBestReflex(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reflexBestKey, score);
  }
}
