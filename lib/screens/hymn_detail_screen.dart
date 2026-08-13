import 'package:flutter/material.dart';

import '../data/favorites_controller.dart';
import '../data/settings_store.dart';
import '../models/hymn.dart';
import '../theme/app_theme.dart';
import '../theme/font_choices.dart';
import '../widgets/entrance.dart';
import '../widgets/gold_divider.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;
  final FavoritesController favorites;

  /// Prefijo del Hero tag, coincidente con el del listado de origen.
  final String heroPrefix;

  const HymnDetailScreen({
    super.key,
    required this.hymn,
    required this.favorites,
    this.heroPrefix = 'todos',
  });

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final _settings = SettingsStore();
  final _scrollController = ScrollController();
  double _fontSize = 18;
  String _fontFamily = 'Inter';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final size = await _settings.loadFontSize();
    final family = await _settings.loadFontFamily();
    if (!mounted) return;
    setState(() {
      _fontSize = size;
      _fontFamily = family;
    });
  }

  Future<void> _changeFontSize(double delta) async {
    final next = (_fontSize + delta).clamp(14.0, 30.0);
    if (next == _fontSize) return;
    await _settings.saveFontSize(next);
    if (!mounted) return;
    setState(() => _fontSize = next);
  }

  Future<void> _changeFontFamily(String family) async {
    if (family == _fontFamily) return;
    await _settings.saveFontFamily(family);
    if (!mounted) return;
    setState(() => _fontFamily = family);
  }

  Future<void> _showFontPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FontPickerSheet(current: _fontFamily),
    );
    if (selected != null) await _changeFontFamily(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Himno ${widget.hymn.numero}',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.favorites,
            builder: (context, _) {
              final fav = widget.favorites.isFavorite(widget.hymn.numero);
              return _FavoriteButton(
                isFavorite: fav,
                onPressed: () => widget.favorites.toggle(widget.hymn.numero),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 136),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EntranceFade(
                          duration: const Duration(milliseconds: 500),
                          child: Center(
                            child: SelectableText(
                              widget.hymn.titulo,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        EntranceFade(
                          delay: const Duration(milliseconds: 80),
                          child: Center(
                            child: Hero(
                              tag: 'himno-${widget.heroPrefix}-${widget.hymn.numero}',
                              child: SelectableText(
                                'Nº ${widget.hymn.numero}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        EntranceFade(
                          delay: const Duration(milliseconds: 160),
                          child: Center(
                            child: SelectableText(
                              widget.hymn.descripcionEstrofas,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        EntranceFade(
                          delay: const Duration(milliseconds: 240),
                          child: const GoldDivider(),
                        ),
                        const SizedBox(height: 20),
                        for (
                          var i = 0;
                          i < widget.hymn.secciones.length;
                          i++
                        ) ...[
                          if (i > 0) const GoldDivider(height: 18),
                          EntranceFade(
                            delay: Duration(milliseconds: 320 + i * 70),
                            duration: const Duration(milliseconds: 450),
                            offset: const Offset(0, 0.04),
                            child: widget.hymn.secciones[i].isChorus
                                ? _ChorusCard(
                                    text: widget.hymn.secciones[i].text,
                                    fontSize: _fontSize,
                                    fontFamily: _fontFamily,
                                  )
                                : _VerseText(
                                    text: widget.hymn.secciones[i].text,
                                    fontSize: _fontSize,
                                    fontFamily: _fontFamily,
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHigh,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                    child: _FontSizeBar(
                      value: _fontSize,
                      onDecrease: () => _changeFontSize(-2),
                      onIncrease: () => _changeFontSize(2),
                      onFontSelected: _showFontPicker,
                    ),
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

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onPressed();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isFavorite
        ? Colors.redAccent
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      tooltip: widget.isFavorite
          ? 'Quitar de favoritos'
          : 'Agregar a favoritos',
      onPressed: _handleTap,
      icon: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(widget.isFavorite),
            color: color,
          ),
        ),
      ),
    );
  }
}

class _FontSizeBar extends StatelessWidget {
  final double value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onFontSelected;

  const _FontSizeBar({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.onFontSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _RoundButton(
                icon: Icons.font_download_outlined,
                tooltip: 'Tipo de letra',
                onPressed: onFontSelected,
              ),
              const SizedBox(width: 16),
              Text(
                'Tamaño de letra',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              _RoundButton(
                icon: Icons.remove,
                tooltip: 'Reducir letra',
                onPressed: value > 14 ? onDecrease : null,
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  '${value.round()}',
                  key: ValueKey(value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: AppFonts.display,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _RoundButton(
                icon: Icons.add,
                tooltip: 'Aumentar letra',
                onPressed: value < 30 ? onIncrease : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHigh,
        disabledBackgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

class _VerseText extends StatelessWidget {
  final String text;
  final double fontSize;
  final String fontFamily;

  const _VerseText({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16))
        .copyWith(fontSize: fontSize, height: 1.6);
    return SelectableText(
      text,
      textAlign: TextAlign.justify,
      style: applyFontFamily(base, fontFamily),
    );
  }
}

class _ChorusCard extends StatelessWidget {
  final String text;
  final double fontSize;
  final String fontFamily;

  const _ChorusCard({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.secondaryContainer.withValues(alpha: 0.35)
            : const Color(0xFFF9F1DC),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.5 : 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'CORO',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: AppFonts.body,
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            text,
            textAlign: TextAlign.justify,
            style: applyFontFamily(
              (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16))
                  .copyWith(
                fontSize: fontSize,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
              fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontPickerSheet extends StatelessWidget {
  final String current;

  const _FontPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
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
                  Text(
                    '$kFontTotalCount estilos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    for (final choice in group.fonts)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          choice.family == current
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: choice.family == current
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        title: Text(
                          choice.label,
                          style: applyFontFamily(
                            theme.textTheme.bodyMedium ??
                                const TextStyle(fontSize: 16),
                            choice.family,
                          ),
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
    );
  }
}
