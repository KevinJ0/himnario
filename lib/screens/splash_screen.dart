import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/entrance.dart';
import 'main_screen.dart';

class SplashScreen extends StatelessWidget {
  final Duration duration;
  final VoidCallback onThemeChanged;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
    this.duration = const Duration(seconds: 1),
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(duration, () {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainScreen(onThemeChanged: onThemeChanged),
        ),
      );
    });
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EntranceFade(
              duration: const Duration(milliseconds: 600),
              offset: const Offset(0, 0.05),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 28),
            EntranceFade(
              delay: const Duration(milliseconds: 250),
              duration: const Duration(milliseconds: 700),
              child: Text(
                'Himnos de Gloria y Triunfo',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            EntranceFade(
              delay: const Duration(milliseconds: 450),
              duration: const Duration(milliseconds: 700),
              child: Text(
                'Letras sagradas para el alma',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: AppFonts.body,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
