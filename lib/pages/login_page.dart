import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/app_tokens.dart';
import '../service/biometric_service.dart';
import '../service/session_service.dart';
import '../widgets/app_card.dart';
import '../widgets/scrim_image.dart';
import 'home_page.dart';

/// Layar masuk dan daftar (akun lokal, SharedPreferences).
/// Setelah daftar, pengguna kembali ke form Masuk dan harus login dulu.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _session = SessionService();
  final _biometric = BiometricService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _biometricUser;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  /// Tombol sidik jari muncul bila akun pernah mengaktifkannya dan HP mendukung.
  Future<void> _loadBiometric() async {
    final user = await _session.biometricUser();
    final available = await _biometric.isAvailable();
    if (!mounted) return;
    setState(() => _biometricUser = available ? user : null);
  }

  Future<void> _loginWithBiometric() async {
    final user = _biometricUser;
    if (user == null) return;
    final ok = await _biometric.authenticate('Verifikasi untuk masuk');
    if (!mounted) return;
    if (!ok) {
      setState(
        () => _error = 'Verifikasi sidik jari gagal. Coba lagi atau masuk dengan password.',
      );
      return;
    }
    await _session.loginWithBiometric(user);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_isRegister) {
      final error = await _session.register(username, password);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _busy = false;
          _error = error;
        });
        return;
      }
      // Akun jadi, tapi pengguna harus masuk lewat form Masuk.
      setState(() {
        _busy = false;
        _isRegister = false;
        _passwordController.clear();
        _confirmController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun dibuat. Silakan masuk.')),
      );
      return;
    }

    final error = await _session.login(username, password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fz = context.fz;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ScrimImage(
            assetPath: AppImages.bgLogin,
            borderRadius: 0,
            scrim: 0.7,
            showPitchPattern: true,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: fz.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sports_soccer,
                          size: 44,
                          color: fz.onAccent,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Ultimate Fanzone',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _isRegister
                            ? 'Buat akun suporter barumu'
                            : 'Teman suporter Premier League-mu',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Username wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 4) {
                                    return 'Password minimal 4 karakter';
                                  }
                                  return null;
                                },
                              ),
                              if (_isRegister) ...[
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  controller: _confirmController,
                                  obscureText: _hidePassword,
                                  decoration: const InputDecoration(
                                    labelText: 'Ulangi password',
                                  ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Password tidak sama';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_isRegister ? 'Daftar' : 'Masuk'),
                              ),
                              if (!_isRegister && _biometricUser != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: _busy ? null : _loginWithBiometric,
                                  icon: const Icon(Icons.fingerprint),
                                  label: const Text('Masuk dengan sidik jari'),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: _busy ? null : _switchMode,
                                child: Text(
                                  _isRegister
                                      ? 'Sudah punya akun? Masuk'
                                      : 'Belum punya akun? Daftar',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
