import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/app_tokens.dart';
import '../model/stadium.dart';
import '../service/biometric_service.dart';
import '../service/notes_service.dart';
import '../service/prediction_service.dart';
import '../service/session_service.dart';
import '../service/settings_service.dart';
import '../service/stamp_service.dart';
import '../widgets/app_card.dart';
import '../widgets/club_crest.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/scrim_image.dart';
import '../widgets/stat_tile.dart';
import 'login_page.dart';
import 'settings_page.dart';

/// Profil: identitas, ringkasan aktivitas, pengaturan, dan keluar.
///
/// [refreshTick] naik tiap pengguna berpindah tab; saat berubah, angka
/// ringkasan dimuat ulang (layar ini disimpan IndexedStack, jadi tidak dibuat
/// ulang sendiri). Klub favorit dibaca dari notifier bersama.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.refreshTick = 0});

  final int refreshTick;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _session = SessionService();
  final _biometric = BiometricService();

  String _username = '';
  int _stamps = 0;
  int _predictions = 0;
  int _notes = 0;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    final user = await _session.currentUser();
    final stamps = await StampService().loadAll();
    final predictions = await PredictionService().loadAll();
    final notes = await NotesService().loadAll();
    final available = await _biometric.isAvailable();
    final biometricUser = await _session.biometricUser();
    if (!mounted) return;
    setState(() {
      _username = user ?? '';
      _stamps = stamps.length;
      _predictions = predictions.length;
      _notes = notes.length;
      _biometricAvailable = available;
      _biometricEnabled = biometricUser != null && biometricUser == user;
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!enable) {
      await _session.disableBiometric();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      return;
    }
    final ok = await _biometric.authenticate(
      'Verifikasi untuk mengaktifkan masuk dengan sidik jari',
    );
    if (!mounted) return;
    if (!ok) {
      _snack('Verifikasi gagal. Masuk dengan sidik jari belum aktif.');
      return;
    }
    await _session.enableBiometric(_username);
    if (!mounted) return;
    setState(() => _biometricEnabled = true);
    _snack('Masuk dengan sidik jari aktif.');
  }

  Future<void> _logout() async {
    await _session.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _header() {
    final theme = Theme.of(context);
    final fz = context.fz;
    final initial = _username.isEmpty ? '?' : _username[0].toUpperCase();
    return ScrimImage(
      assetPath: AppImages.bgLogin,
      height: 190,
      borderRadius: 0,
      scrim: 0.75,
      showPitchPattern: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: fz.surfaceHigh,
                  child: Text(initial, style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Suporter Ultimate Fanzone',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _favoriteRow(String? favorite) {
    final fz = context.fz;
    return AppCard(
      child: Row(
        children: [
          favorite == null
              ? const Icon(Icons.star_border, size: 36)
              : ClubCrest(name: favorite, size: 40),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite ?? 'Belum ada klub favorit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  favorite == null
                      ? 'Pilih lewat ikon bintang di tab Laga'
                      : (stadiumOfClub(favorite)?.name ?? 'Klub favoritmu'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: fz.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fz = context.fz;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(label: 'Stempel', value: _stamps),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(label: 'Tebakan', value: _predictions),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(label: 'Catatan', value: _notes),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  index: 1,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: SettingsService.favoriteNotifier,
                    builder: (context, favorite, _) => _favoriteRow(favorite),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  index: 2,
                  child: AppCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune),
                        const SizedBox(width: AppSpacing.lg),
                        const Expanded(child: Text('Pengaturan suporter')),
                        Icon(Icons.chevron_right, color: fz.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  index: 3,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Masuk dengan sidik jari'),
                      subtitle: Text(
                        _biometricAvailable
                            ? 'Lewati password di layar masuk'
                            : 'Tidak tersedia di HP ini',
                      ),
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable ? _toggleBiometric : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  index: 4,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
