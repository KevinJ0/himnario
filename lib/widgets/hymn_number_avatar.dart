import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Variante visual del avatar de número.
enum HymnAvatarStyle {
  /// Lista: fondo púrpura tenue en claro / contenedor primario en oscuro.
  list,

  /// Grid y cabeceras: contenedor primario con texto «onPrimaryContainer».
  grid,
}

/// Avatar circular con el número del himno. Centraliza el estilo para que el
/// listado, el historial y el detalle compartan la misma apariencia.
class HymnNumberAvatar extends StatelessWidget {
  final int numero;
  final HymnAvatarStyle style;

  const HymnNumberAvatar({
    super.key,
    required this.numero,
    this.style = HymnAvatarStyle.list,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final (background, foreground) = switch (style) {
      HymnAvatarStyle.list => (
        isDark
            ? scheme.primaryContainer
            : AppColors.purple.withValues(alpha: 0.1),
        scheme.primary,
      ),
      HymnAvatarStyle.grid => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };

    return CircleAvatar(
      backgroundColor: background,
      child: Text(
        '$numero',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontFamily: AppFonts.display,
        ),
      ),
    );
  }
}
