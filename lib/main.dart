import 'package:flutter/material.dart';

import 'data/settings_store.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsStore();
  final themeMode = await settings.loadThemeMode();
  runApp(HimnarioApp(settings: settings, initialThemeMode: themeMode));
}

class HimnarioApp extends StatefulWidget {
  final SettingsStore settings;
  final ThemeMode initialThemeMode;

  const HimnarioApp({
    super.key,
    required this.settings,
    required this.initialThemeMode,
  });

  @override
  State<HimnarioApp> createState() => _HimnarioAppState();
}

class _HimnarioAppState extends State<HimnarioApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  Future<void> _toggleTheme() async {
    final next = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await widget.settings.saveThemeMode(next);
    if (!mounted) return;
    setState(() => _themeMode = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Himnos de Gloria y Triunfo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      home: SplashScreen(onThemeChanged: _toggleTheme),
    );
  }
}