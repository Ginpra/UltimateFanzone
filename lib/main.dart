import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'service/notification_service.dart';
import 'service/session_service.dart';
import 'service/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotificationService().init();
  await SettingsService().loadFavoriteClub();

  // Sudah login sebelumnya? Langsung ke Home, kalau belum ke layar Login.
  final user = await SessionService().currentUser();
  runApp(
    FanzoneApp(startPage: user == null ? const LoginPage() : const HomePage()),
  );
}

class FanzoneApp extends StatelessWidget {
  const FanzoneApp({super.key, required this.startPage});

  final Widget startPage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Fanzone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: startPage,
    );
  }
}
