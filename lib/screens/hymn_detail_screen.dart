import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/favorites_controller.dart';
import '../data/settings_store.dart';
import '../models/hymn.dart';
import '../services/hymn_share_service.dart';
import '../theme/app_theme.dart';
import '../theme/font_choices.dart';
import '../widgets/entrance.dart';
import '../widgets/favorite_button.dart';
import '../widgets/font_picker_sheet.dart';
import '../widgets/gold_divider.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;
  final FavoritesController favorites;

  /// Prefijo del Hero tag, coincidente con el del listado de origen.
  final String heroPrefix;

  const HymnDetailScreen({super.key, required this.hymn, required this.favorites, this.heroPrefix = 'todos'});

  /// Formato único del Hero tag de un himno, compartido con los listados.
  static String heroTag(String prefix, int numero) => 'himno-$prefix-$numero';

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> with WidgetsBindingObserver {
  final _settings = SettingsStore();
  final _scrollController = ScrollController();
  double _fontSize = 18;
  String _fontFamily = 'Inter';
  bool _keepScreenOn = false;
  bool _readingMode = false;
  bool _controlsVisible = true;
  bool _immersiveActive = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    if (_readingMode) _settings.saveReadingMode(false);
    if (_immersiveActive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    WakelockPlus.disable();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyWakelock();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      WakelockPlus.disable();
    }
  }

  Future<void> _loadSettings() async {
    final size = await _settings.loadFontSize();
    final family = await _settings.loadFontFamily();
    final keepScreenOn = await _settings.loadKeepScreenOn();
    final readingMode = await _settings.loadReadingMode();
    if (!mounted) return;
    setState(() {
      _fontSize = size;
      _fontFamily = family;
      _keepScreenOn = keepScreenOn;
      _readingMode = readingMode;
    });
    await _applyWakelock();
    if (readingMode) await _enterReadingMode(persist: false);
  }

  Future<void> _applyWakelock() async {
    if (_keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  Future<void> _toggleKeepScreenOn() async {
    final next = !_keepScreenOn;
    await _settings.saveKeepScreenOn(next);
    if (!mounted) return;
    setState(() => _keepScreenOn = next);
    await _applyWakelock();
  }

  Future<void> _enterReadingMode({bool persist = true}) async {
    if (persist) await _settings.saveReadingMode(true);
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() {
      _readingMode = true;
      _controlsVisible = true;
    });
    _setImmersive(true);
    _startHideTimer();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Future<void> _exitReadingMode() async {
    _hideTimer?.cancel();
    await _settings.saveReadingMode(false);
    if (!mounted) return;
    setState(() {
      _readingMode = false;
      _controlsVisible = true;
    });
    _setImmersive(false);
  }

  void _setImmersive(bool active) {
    if (active == _immersiveActive) return;
    _immersiveActive = active;
    SystemChrome.setEnabledSystemUIMode(active ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_readingMode) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (!mounted || !_readingMode) return;
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _FontPickerSheetWrapper(current: _fontFamily),
          ),
        ),
      ),
    );
    if (selected != null) await _changeFontFamily(selected);
  }

  bool _sharing = false;

  Future<void> _shareHymn() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await HymnShareService.share(context, widget.hymn);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo generar la imagen: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (_readingMode) {
      return _buildReadingMode(theme, colorScheme);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Himno ${widget.hymn.numero}', style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Compartir como imagen',
            icon: _sharing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_outlined),
            onPressed: _sharing ? null : _shareHymn,
          ),
          ListenableBuilder(
            listenable: widget.favorites,
            builder: (context, _) {
              final fav = widget.favorites.isFavorite(widget.hymn.numero);
              return FavoriteButton(isFavorite: fav, onPressed: () => widget.favorites.toggle(widget.hymn.numero));
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
                              style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        EntranceFade(
                          delay: const Duration(milliseconds: 80),
                          child: Center(
                            child: Hero(
                              tag: HymnDetailScreen.heroTag(widget.heroPrefix, widget.hymn.numero),
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
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        EntranceFade(delay: const Duration(milliseconds: 240), child: const GoldDivider()),
                        const SizedBox(height: 20),
                        for (var i = 0; i < widget.hymn.secciones.length; i++) ...[
                          if (i > 0) const GoldDivider(height: 18),
                          EntranceFade(
                            delay: Duration(milliseconds: 320 + i * 70),
                            duration: const Duration(milliseconds: 450),
                            offset: const Offset(0, 0.04),
                            child: widget.hymn.secciones[i].isChorus
                                ? _ChorusCard(text: widget.hymn.secciones[i].text, fontSize: _fontSize, fontFamily: _fontFamily)
                                : _VerseText(text: widget.hymn.secciones[i].text, fontSize: _fontSize, fontFamily: _fontFamily),
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
            bottom: 15,
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
                      keepScreenOn: _keepScreenOn,
                      onToggleKeepScreenOn: _toggleKeepScreenOn,
                      onReadingMode: _enterReadingMode,
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

  Widget _buildReadingMode(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(32, 72, 32, 144),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SelectableText(
                              widget.hymn.titulo,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SelectableText(
                              'Nº ${widget.hymn.numero}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Center(child: GoldDivider()),
                          const SizedBox(height: 28),
                          for (var i = 0; i < widget.hymn.secciones.length; i++) ...[
                            if (i > 0) const SizedBox(height: 22),
                            widget.hymn.secciones[i].isChorus
                                ? _ChorusCard(text: widget.hymn.secciones[i].text, fontSize: _fontSize, fontFamily: _fontFamily)
                                : _VerseText(text: widget.hymn.secciones[i].text, fontSize: _fontSize, fontFamily: _fontFamily),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ListenableBuilder(
              listenable: widget.favorites,
              builder: (context, _) => _ReadingTopBar(
                visible: _controlsVisible,
                isFavorite: widget.favorites.isFavorite(widget.hymn.numero),
                onExit: _exitReadingMode,
                onToggleFavorite: () => widget.favorites.toggle(widget.hymn.numero),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReadingBottomBar(
              visible: _controlsVisible,
              value: _fontSize,
              onDecrease: () {
                _startHideTimer();
                _changeFontSize(-2);
              },
              onIncrease: () {
                _startHideTimer();
                _changeFontSize(2);
              },
              onFontSelected: _showFontPicker,
              onShare: _shareHymn,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontSizeBar extends StatelessWidget {
  final double value;
  final bool keepScreenOn;
  final VoidCallback onToggleKeepScreenOn;
  final VoidCallback onReadingMode;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onFontSelected;

  const _FontSizeBar({
    required this.value,
    required this.keepScreenOn,
    required this.onToggleKeepScreenOn,
    required this.onReadingMode,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              final gap = compact ? 4.0 : 8.0;
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _RoundButton(icon: Icons.menu_book_outlined, tooltip: 'Modo lectura', onPressed: onReadingMode),
                    SizedBox(width: gap),
                    _RoundButton(icon: Icons.font_download_outlined, tooltip: 'Tipo de letra', onPressed: onFontSelected),
                    if (compact)
                      const SizedBox(width: 8)
                    else ...[
                      const SizedBox(width: 16),
                      Text('Tamaño de letra', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                    ],
                    _RoundButton(icon: Icons.remove, tooltip: 'Reducir letra', onPressed: value > 14 ? onDecrease : null),
                    SizedBox(width: gap),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${value.round()}',
                        key: ValueKey(value),
                        style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppFonts.display),
                      ),
                    ),
                    SizedBox(width: gap),
                    _RoundButton(icon: Icons.add, tooltip: 'Aumentar letra', onPressed: value < 30 ? onIncrease : null),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReadingTopBar extends StatelessWidget {
  final bool visible;
  final bool isFavorite;
  final VoidCallback onExit;
  final VoidCallback onToggleFavorite;

  const _ReadingTopBar({required this.visible, required this.isFavorite, required this.onExit, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1.4),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.92),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    IconButton(tooltip: 'Salir del modo lectura', icon: const Icon(Icons.fullscreen_exit), onPressed: onExit),
                    Expanded(
                      child: Text(
                        'Modo lectura',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w600),
                      ),
                    ),
                    FavoriteButton(isFavorite: isFavorite, onPressed: onToggleFavorite),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingBottomBar extends StatelessWidget {
  final bool visible;
  final double value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onFontSelected;
  final VoidCallback onShare;

  const _ReadingBottomBar({
    required this.visible,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.onFontSelected,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.92),
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(icon: Icons.text_decrease, tooltip: 'Reducir letra', onPressed: value > 14 ? onDecrease : null),
                  const SizedBox(width: 12),
                  Text(
                    '${value.round()}',
                    style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  _RoundButton(icon: Icons.text_increase, tooltip: 'Aumentar letra', onPressed: value < 30 ? onIncrease : null),
                  const SizedBox(width: 28),
                  _RoundButton(icon: Icons.font_download_outlined, tooltip: 'Tipo de letra', onPressed: onFontSelected),
                  const SizedBox(width: 28),
                  _RoundButton(icon: Icons.share_outlined, tooltip: 'Compartir', onPressed: onShare),
                ],
              ),
            ),
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

  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

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

  const _VerseText({required this.text, required this.fontSize, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(fontSize: fontSize, height: 1.6);
    return SelectableText(text, textAlign: TextAlign.start, style: applyFontFamily(base, fontFamily));
  }
}

class _ChorusCard extends StatelessWidget {
  final String text;
  final double fontSize;
  final String fontFamily;

  const _ChorusCard({required this.text, required this.fontSize, required this.fontFamily});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.secondaryContainer.withValues(alpha: 0.35) : const Color(0xFFF9F1DC),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.gold.withValues(alpha: isDark ? 0.5 : 0.55)),
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
            textAlign: TextAlign.start,
            style: applyFontFamily(
              (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(fontSize: fontSize, height: 1.6, fontWeight: FontWeight.w600),
              fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// Envoltura local del selector compartido de tipos de letra: mantiene el
/// ancho máximo y el anclaje inferior sin duplicar la hoja.
class _FontPickerSheetWrapper extends StatelessWidget {
  final String current;

  const _FontPickerSheetWrapper({required this.current});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: FontPickerSheet(current: current),
      ),
    );
  }
}
