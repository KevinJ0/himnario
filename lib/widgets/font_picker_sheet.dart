import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/font_choices.dart';

/// Hoja inferior con el catálogo completo de tipos de letra, agrupados por
/// estilo. Devuelve la familia seleccionada vía `Navigator.pop`.
class FontPickerSheet extends StatelessWidget {
  final String current;

  const FontPickerSheet({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.gold.withValues(alpha: isDark ? 0.9 : 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.font_download_outlined, color: colorScheme.secondary),
                    const SizedBox(width: 10),
                    Text('Tipo de letra', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text('$kFontTotalCount estilos', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final group in kFontGroups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          group.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                        ),
                      ),
                      for (final choice in group.fonts)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            choice.family == current ? Icons.check_circle : Icons.circle_outlined,
                            color: choice.family == current ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(
                            choice.label,
                            style: applyFontFamily(theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 16), choice.family),
                          ),
                          onTap: () => Navigator.of(context).pop(choice.family),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}