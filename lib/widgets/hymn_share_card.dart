import 'package:flutter/material.dart';

import '../models/hymn.dart';
import '../theme/app_theme.dart';
import 'gold_divider.dart';

/// Ancho lógico (px) con el que se compone la tarjeta para la captura.
const double kShareCardWidth = 1080;

/// Representación independiente del himno para compartir como imagen.
/// No se usa en la pantalla normal: solo se construye fuera de ella para
/// renderizarse en un RepaintBoundary y capturarse.
class HymnShareCard extends StatelessWidget {
  final Hymn hymn;

  const HymnShareCard({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final gold = AppColors.gold;
    final bg = isDark
        ? const [AppColors.darkPurple, Color(0xFF241737)]
        : const [Color(0xFFFDFBF6), Color(0xFFF7EDD4)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bg,
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(44, 48, 44, 56),
        decoration: BoxDecoration(
          border: Border.all(
            color: gold.withValues(alpha: isDark ? 0.85 : 0.7),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HIMNOS DE GLORIA Y TRIUNFO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: gold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            GoldDivider(height: 14, color: gold),
            const SizedBox(height: 30),
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: gold.withValues(alpha: isDark ? 0.9 : 0.75),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${hymn.numero}',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.purpleMid : AppColors.purple,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hymn.titulo.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 20),
            GoldDivider(
              height: 10,
              color: gold.withValues(alpha: isDark ? 0.85 : 0.8),
            ),
            const SizedBox(height: 34),
            for (var i = 0; i < hymn.secciones.length; i++) ...[
              _ShareSection(
                section: hymn.secciones[i],
                isDark: isDark,
                isLast: i == hymn.secciones.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  final HymnSection section;
  final bool isDark;
  final bool isLast;

  const _ShareSection({
    required this.section,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final gold = AppColors.gold;

    if (section.isChorus) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: isLast ? 0 : 26),
        padding: const EdgeInsets.fromLTRB(30, 26, 30, 30),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.gold.withValues(alpha: 0.12)
              : AppColors.goldTint.withValues(alpha: 0.45),
          border: Border.all(color: gold.withValues(alpha: 0.55), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CORO',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: gold,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Text(
                section.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Text(
          section.text,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 23,
            fontWeight: FontWeight.w400,
            color: textColor,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
