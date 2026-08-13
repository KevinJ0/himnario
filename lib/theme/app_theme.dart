import 'package:flutter/material.dart';

import '../widgets/page_transitions.dart';

/// Identidad visual "Sacred Liturgy" de Himnos de Gloria y Triunfo.
abstract final class AppColors {
  AppColors._();

  /// Púrpura principal: realeza y divinidad. Números, iconos activos y acentos.
  static const Color purple = Color(0xFF5C3A99);

  /// Dorado suave: elegancia y elementos de realce.
  static const Color gold = Color(0xFFD4AF37);

  /// Fondo crema (modo claro): lectura descansada, papel de libro antiguo.
  static const Color cream = Color(0xFFFBF9F5);

  /// Fondo oscuro: púrpura casi negro.
  static const Color darkPurple = Color(0xFF1A1226);

  static const Color purpleLight = Color(0xFFEDE7F5);
  static const Color purpleMid = Color(0xFFB79BF0);
  static const Color purpleDeep = Color(0xFF2A1B4D);
  static const Color goldDeep = Color(0xFF8A6D1A);
  static const Color goldTint = Color(0xFFF3E7C3);

  static const Color textLight = Color(0xFF241B33);
  static const Color textLightMuted = Color(0xFF5C5566);
  static const Color textDark = Color(0xFFF0EBFA);
  static const Color textDarkMuted = Color(0xFFB4ABBF);

  static const Color surfaceLightRaised = Color(0xFFEFE9DF);
  static const Color surfaceDarkRaised = Color(0xFF2E2340);

  static const Color outlineLight = Color(0xFFD9D2E2);
  static const Color outlineDark = Color(0xFF4A3E5C);

  // ── Paleta "Hymnal Desktop" (bandas anchas ≥ 900px) ──────────────────────
  // Azul marino profundo para texto, lavanda suave para acentos y blancos
  // cálidos para el papel texturizado, en modo claro.
  static const Color navy = Color(0xFF22304F);
  static const Color navyMuted = Color(0xFF5D6882);
  static const Color navySoft = Color(0xFF16203A);
  static const Color navyRaised = Color(0xFF1D2948);
  static const Color navyBorder = Color(0xFF31406A);
  static const Color lavender = Color(0xFF8D7BC4);
  static const Color lavenderSoft = Color(0xFFEAE3F7);
  static const Color lavenderMid = Color(0xFFC9B9EC);

  static const Color paper = Color(0xFFF5F0E6);
  static const Color paperRaised = Color(0xFFFDFBF5);
  static const Color paperBorder = Color(0xFFE8E0CE);

  static const Color chorusCream = Color(0xFFFAF3E1);
  static const Color chorusCreamBorder = Color(0xFFE9D9AE);
  static const Color chorusNavyBorder = Color(0xFF48597F);
}

/// Tokens de forma del sistema de diseño.
abstract final class AppRadius {
  AppRadius._();

  /// ROUND_FOUR: bordes suaves de 4px.
  static const double card = 4;
}

/// Tipografía empaquetada: EB Garamond (serif) para títulos e
/// Inter (sans-serif) para cuerpo e interfaz.
abstract final class AppFonts {
  AppFonts._();

  static const String display = 'EBGaramond';
  static const String body = 'Inter';
}

/// Temas claro y oscuro de la app.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.purpleMid : AppColors.purple,
          onPrimary: isDark ? AppColors.purpleDeep : Colors.white,
          primaryContainer: isDark
              ? const Color(0xFF3A2A5C)
              : AppColors.purpleLight,
          onPrimaryContainer: isDark ? AppColors.purpleMid : AppColors.purple,
          secondary: AppColors.gold,
          onSecondary: AppColors.goldDeep,
          secondaryContainer: isDark
              ? const Color(0xFF4A3F14)
              : AppColors.goldTint,
          onSecondaryContainer: isDark
              ? AppColors.goldTint
              : AppColors.goldDeep,
          surface: isDark ? AppColors.darkPurple : AppColors.cream,
          onSurface: isDark ? AppColors.textDark : AppColors.textLight,
          surfaceContainerHighest: isDark
              ? AppColors.surfaceDarkRaised
              : AppColors.surfaceLightRaised,
          onSurfaceVariant: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          outline: isDark ? const Color(0xFF8F86A0) : const Color(0xFF857B8F),
          outlineVariant: isDark
              ? AppColors.outlineDark
              : AppColors.outlineLight,
          surfaceTint: Colors.transparent,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(scheme),
      scaffoldBackgroundColor: scheme.surface,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _serif(20, FontWeight.w700, scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _sans(
            12,
            selected ? FontWeight.w700 : FontWeight.w500,
            selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: _sans(14, FontWeight.w600, null),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.4 : 1,
            );
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? scheme.onPrimary : scheme.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected ? scheme.primary : scheme.surfaceContainerHighest;
          }),
          textStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return _sans(
              13,
              selected ? FontWeight.w700 : FontWeight.w500,
              null,
            );
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final c = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    return TextTheme(
      displayLarge: _serif(57, FontWeight.w600, c, 1.12),
      displayMedium: _serif(45, FontWeight.w600, c, 1.16),
      displaySmall: _serif(36, FontWeight.w700, c, 1.22),
      headlineLarge: _serif(32, FontWeight.w700, c, 1.25),
      headlineMedium: _serif(28, FontWeight.w700, c, 1.29),
      headlineSmall: _serif(24, FontWeight.w700, c, 1.33),
      titleLarge: _serif(22, FontWeight.w600, c, 1.27),
      titleMedium: _sans(16, FontWeight.w600, c, 1.5),
      titleSmall: _sans(14, FontWeight.w600, c, 1.43),
      bodyLarge: _sans(16, FontWeight.w400, c, 1.5),
      bodyMedium: _sans(14, FontWeight.w400, c, 1.43),
      bodySmall: _sans(12, FontWeight.w400, muted, 1.33),
      labelLarge: _sans(14, FontWeight.w600, c, 1.43),
      labelMedium: _sans(12, FontWeight.w500, c, 1.33),
      labelSmall: _sans(11, FontWeight.w500, muted, 1.45),
    );
  }

  static TextStyle _serif(
    double size,
    FontWeight weight,
    Color color, [
    double? height,
  ]) {
    return TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle _sans(
    double size,
    FontWeight weight,
    Color? color, [
    double? height,
  ]) {
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}
