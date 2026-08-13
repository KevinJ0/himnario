import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/favorites_controller.dart';
import '../data/recent_hymns_controller.dart';
import '../data/settings_store.dart';
import '../models/hymn.dart';
import '../services/hymn_share_service.dart';
import '../services/hymn_search.dart';
import '../theme/app_theme.dart';
import '../theme/font_choices.dart';
import '../widgets/entrance.dart';
import '../widgets/favorite_button.dart';
import '../widgets/font_picker_sheet.dart';
import '../widgets/gold_divider.dart';
import '../widgets/hymn_number_avatar.dart';
import '../widgets/logo_mark.dart';

enum _DesktopOrder { numero, titulo }

/// Vista de pantalla ancha (bandas ≥ 900px): panel dividido con la lista de
/// himnos a la izquierda y la vista completa del himno seleccionado a la
/// derecha, sobre un fondo de papel texturizado con paleta azul marino y
/// lavanda.
class DesktopHymnLayout extends StatefulWidget {
  final List<Hymn> himnos;
  final FavoritesController favorites;
  final RecentHymnsController recents;
  final VoidCallback onThemeChanged;

  const DesktopHymnLayout({
    super.key,
    required this.himnos,
    required this.favorites,
    required this.recents,
    required this.onThemeChanged,
  });

  @override
  State<DesktopHymnLayout> createState() => _DesktopHymnLayoutState();
}

class _DesktopHymnLayoutState extends State<DesktopHymnLayout> {
  final _settings = SettingsStore();
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _detailController = ScrollController();

  late Map<int, String> _normMap;
  String _query = '';
  _DesktopOrder _order = _DesktopOrder.numero;
  int _tab = 0;
  int? _selectedNumero;

  double _fontSize = 18;
  String _fontFamily = 'Inter';
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _normMap = HymnSearch.buildNormMap(widget.himnos);
    if (widget.himnos.isNotEmpty) {
      _selectedNumero = widget.himnos.first.numero;
    }
    _loadSettings();
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

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  List<Hymn> _filteredFor(int tab) {
    return HymnSearch.filter(
      source: widget.himnos,
      normMap: _normMap,
      query: _query,
      showFavoritesOnly: tab == 1,
      favoriteIds: widget.favorites.ids,
      sortAlphabetically: _order == _DesktopOrder.titulo,
    );
  }

  /// Himno efectivo del panel derecho: conserva la selección mientras siga
  /// dentro del filtro actual; si no, cae al primero del listado.
  Hymn? _effectiveFor(List<Hymn> filtered) {
    if (filtered.isEmpty) return null;
    for (final hymn in filtered) {
      if (hymn.numero == _selectedNumero) return hymn;
    }
    return filtered.first;
  }

  void _scrollDetailToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _detailController.hasClients) {
        _detailController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectHymn(Hymn hymn) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.recents.record(hymn.numero);
    setState(() => _selectedNumero = hymn.numero);
    _scrollDetailToTop();
  }

  void _switchTab(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (_listController.hasClients) _listController.jumpTo(0);
    _scrollDetailToTop();
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
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
            child: FontPickerSheet(current: _fontFamily),
          ),
        ),
      ),
    );
    if (selected != null) await _changeFontFamily(selected);
  }

  Future<void> _shareHymn(Hymn hymn) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await HymnShareService.share(context, hymn);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo generar la imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _openRecents() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final byNum = {for (final h in widget.himnos) h.numero: h};
    final hymns = <Hymn>[for (final id in widget.recents.ids) ?byNum[id]];
    if (hymns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no has abierto himnos')),
      );
      return;
    }
    final picked = await showModalBottomSheet<Hymn>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 500),
            child: _RecentsSheet(
              hymns: hymns,
              favorites: widget.favorites,
              recents: widget.recents,
              onSelect: Navigator.of(context).pop,
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      _switchTab(0);
      _selectHymn(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final paper = isDark ? AppColors.navySoft : AppColors.paper;

    return Scaffold(
      backgroundColor: paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PaperTexturePainter(dark: isDark)),
          ),
          Positioned.fill(
            child: SafeArea(
              child: ListenableBuilder(
                listenable: Listenable.merge(
                  [widget.favorites, widget.recents],
                ),
                builder: (context, _) {
                  final filtered = _filteredFor(_tab);
                  final effective = _effectiveFor(filtered);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 380,
                        child: _buildLeftPane(theme, isDark, filtered, effective),
                      ),
                      Expanded(
                        child: effective == null
                            ? _buildEmptyDetail(theme, isDark)
                            : _buildDetail(theme, isDark, effective),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel izquierdo ──────────────────────────────────────────────────────

  Widget _buildLeftPane(
    ThemeData theme,
    bool isDark,
    List<Hymn> filtered,
    Hymn? effective,
  ) {
    final raised = isDark ? AppColors.navyRaised : AppColors.paperRaised;
    final border = isDark ? AppColors.navyBorder : AppColors.paperBorder;
    return Container(
      decoration: BoxDecoration(
        color: raised.withValues(alpha: isDark ? 0.92 : 0.9),
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme, isDark),
          _buildTabs(theme, isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildSearchField(theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildOrderToggle(theme),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList(theme, isDark, filtered, effective)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          const LogoMark(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Himnos de Gloria y Triunfo',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: AppFonts.display,
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Himnario digital',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Historial',
            icon: Icon(Icons.history, color: muted),
            onPressed: _openRecents,
          ),
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: muted,
            ),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme, bool isDark) {
    final track = isDark
        ? AppColors.navySoft
        : AppColors.lavenderSoft.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Himnos',
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book,
              selected: _tab == 0,
              isDark: isDark,
              onTap: () => _switchTab(0),
            ),
            _TabButton(
              label: 'Favoritos',
              icon: Icons.favorite_border,
              selectedIcon: Icons.favorite,
              selected: _tab == 1,
              isDark: isDark,
              onTap: () => _switchTab(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por número o título',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                icon: const Icon(Icons.clear),
                onPressed: _clearQuery,
              ),
      ),
      onChanged: (value) => setState(() => _query = value),
    );
  }

  Widget _buildOrderToggle(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_DesktopOrder>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _DesktopOrder.numero,
            label: Text('Por número'),
          ),
          ButtonSegment(
            value: _DesktopOrder.titulo,
            label: Text('Alfabético'),
          ),
        ],
        selected: {_order},
        onSelectionChanged: (selection) {
          setState(() => _order = selection.first);
          if (_listController.hasClients) _listController.jumpTo(0);
        },
      ),
    );
  }

  Widget _buildList(
    ThemeData theme,
    bool isDark,
    List<Hymn> filtered,
    Hymn? effective,
  ) {
    if (filtered.isEmpty) {
      return _buildLeftEmpty(theme, isDark);
    }
    final separator =
        (isDark ? AppColors.navyBorder : AppColors.paperBorder).withValues(
          alpha: 0.55,
        );
    return Scrollbar(
      controller: _listController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _listController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 20,
          endIndent: 44,
          color: separator,
        ),
        itemBuilder: (context, index) {
          final hymn = filtered[index];
          return _DesktopListTile(
            hymn: hymn,
            isFavorite: widget.favorites.isFavorite(hymn.numero),
            selected: hymn.numero == effective?.numero,
            isDark: isDark,
            onTap: () => _selectHymn(hymn),
            onToggleFavorite: () => widget.favorites.toggle(hymn.numero),
          );
        },
      ),
    );
  }

  Widget _buildLeftEmpty(ThemeData theme, bool isDark) {
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 56),
            const SizedBox(height: 14),
            Text(
              _tab == 1
                  ? 'Aún no tienes favoritos'
                  : 'No se encontraron himnos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tab == 1
                  ? 'Toca el corazón en un himno para guardarlo aquí.'
                  : 'Prueba con otra búsqueda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Panel derecho ────────────────────────────────────────────────────────

  Widget _buildDetail(ThemeData theme, bool isDark, Hymn hymn) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Scrollbar(
                controller: _detailController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _detailController,
                  padding: const EdgeInsets.fromLTRB(40, 48, 40, 148),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntranceFade(
                        duration: const Duration(milliseconds: 500),
                        child: _buildHeaderBlock(theme, isDark, hymn),
                      ),
                      const SizedBox(height: 20),
                      EntranceFade(
                        delay: const Duration(milliseconds: 120),
                        child: const GoldDivider(),
                      ),
                      const SizedBox(height: 24),
                      for (var i = 0; i < hymn.secciones.length; i++) ...[
                        if (i > 0) const GoldDivider(height: 20),
                        EntranceFade(
                          delay: Duration(milliseconds: 140 + i * 60),
                          duration: const Duration(milliseconds: 400),
                          child: hymn.secciones[i].isChorus
                              ? _DesktopChorus(
                                  text: hymn.secciones[i].text,
                                  fontSize: _fontSize,
                                  fontFamily: _fontFamily,
                                )
                              : _DesktopVerse(
                                  text: hymn.secciones[i].text,
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
          bottom: 24,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _DesktopControlsBar(
                value: _fontSize,
                sharing: _sharing,
                isDark: isDark,
                onDecrease: () => _changeFontSize(-2),
                onIncrease: () => _changeFontSize(2),
                onFontSelected: _showFontPicker,
                onShare: () => _shareHymn(hymn),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBlock(ThemeData theme, bool isDark, Hymn hymn) {
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    final accent = isDark ? AppColors.lavender : AppColors.lavender;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hymn.titulo,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: 34,
            color: ink,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                ),
              ),
              child: Text(
                'Nº ${hymn.numero}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hymn.descripcionEstrofas,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyDetail(ThemeData theme, bool isDark) {
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoMark(size: 88),
          const SizedBox(height: 20),
          Text(
            'Selecciona un himno',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca un himno de la lista para ver su letra completa.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// Textura sutil de papel/lino premium: hilo fino cada 3px, motas
/// deterministas y una viñeta muy tenue en los bordes.
class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final thread = Paint()
      ..color = dark ? const Color(0x0F9FB4E0) : const Color(0x14000000)
      ..strokeWidth = 0.5;
    const step = 3.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thread);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thread);
    }

    final fleck = Paint()
      ..color = dark ? const Color(0x0F6480B0) : const Color(0x16000000);
    final rnd = math.Random(1337);
    final count = ((size.width * size.height) / 2400).round();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 0.4 + rnd.nextDouble() * 0.7;
      canvas.drawCircle(Offset(x, y), r, fleck);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          Colors.black.withValues(alpha: dark ? 0.12 : 0.06),
        ],
        stops: const [0.0, 0.68, 1.0],
        focal: Alignment.center,
        focalRadius: 0.1,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter old) => old.dark != dark;
}

/// Fila de la lista de himnos: avatar circular lavanda con el número, título
/// en serif y corazón de favorito. Resalta al pasar el mouse y marca la
/// selección con una banda lateral.
class _DesktopListTile extends StatelessWidget {
  final Hymn hymn;
  final bool isFavorite;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _DesktopListTile({
    required this.hymn,
    required this.isFavorite,
    required this.selected,
    required this.isDark,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    final selectedColor = isDark ? AppColors.navyBorder : AppColors.lavenderSoft;
    final accent = isDark ? AppColors.lavenderMid : AppColors.lavender;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: selectedColor.withValues(alpha: isDark ? 0.5 : 0.55),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: isDark ? 0.6 : 0.9)
                : Colors.transparent,
            border: selected
                ? Border(
                    left: BorderSide(color: accent, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              HymnNumberAvatar(numero: hymn.numero),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hymn.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hymn.descripcionEstrofas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              FavoriteButton(
                isFavorite: isFavorite,
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pestañas de la cabecera izquierda: Himnos / Favoritos.
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final muted = isDark ? const Color(0xFF8FA0C4) : AppColors.navyMuted;
    final raised = isDark ? AppColors.navyBorder : AppColors.paperRaised;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? raised : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.07,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 17,
                color: selected ? ink : muted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? ink : muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estrofa del panel derecho: sans-serif de alta legibilidad en azul marino.
class _DesktopVerse extends StatelessWidget {
  final String text;
  final double fontSize;
  final String fontFamily;

  const _DesktopVerse({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    return SelectableText(
      text,
      textAlign: TextAlign.start,
      style: applyFontFamily(
        (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
          fontSize: fontSize,
          height: 1.7,
          color: ink,
        ),
        fontFamily,
      ),
    );
  }
}

/// Coro del panel derecho: recuadro crema con esquinas redondeadas, icono de
/// nota musical y borde dorado sutil.
class _DesktopChorus extends StatelessWidget {
  final String text;
  final double fontSize;
  final String fontFamily;

  const _DesktopChorus({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cream = isDark ? const Color(0xFF2B2A1F) : AppColors.chorusCream;
    final border = isDark
        ? AppColors.chorusNavyBorder
        : AppColors.chorusCreamBorder;
    final label = isDark ? AppColors.gold : AppColors.goldDeep;
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, size: 18, color: label),
              const SizedBox(width: 8),
              Text(
                'CORO',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: AppFonts.body,
                  color: label,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            text,
            textAlign: TextAlign.start,
            style: applyFontFamily(
              (theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16))
                  .copyWith(
                    fontSize: fontSize,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
              fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra flotante de control tipográfico con forma de píldora.
class _DesktopControlsBar extends StatelessWidget {
  final double value;
  final bool sharing;
  final bool isDark;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onFontSelected;
  final VoidCallback onShare;

  const _DesktopControlsBar({
    required this.value,
    required this.sharing,
    required this.isDark,
    required this.onDecrease,
    required this.onIncrease,
    required this.onFontSelected,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final raised = isDark ? AppColors.navyRaised : AppColors.paperRaised;
    final border = isDark ? AppColors.navyBorder : AppColors.paperBorder;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: raised.withValues(alpha: isDark ? 0.95 : 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DesktopRoundButton(
            icon: Icons.remove,
            tooltip: 'Reducir letra',
            onPressed: value > 14 ? onDecrease : null,
          ),
          const SizedBox(width: 4),
          Text(
            '${value.round()}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(width: 4),
          _DesktopRoundButton(
            icon: Icons.add,
            tooltip: 'Aumentar letra',
            onPressed: value < 30 ? onIncrease : null,
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 22,
            color: border,
          ),
          const SizedBox(width: 6),
          _DesktopRoundButton(
            icon: Icons.font_download_outlined,
            tooltip: 'Tipo de letra',
            onPressed: onFontSelected,
          ),
          _DesktopRoundButton(
            icon: Icons.share_outlined,
            tooltip: 'Compartir como imagen',
            onPressed: sharing ? null : onShare,
            iconOverride: sharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DesktopRoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget? iconOverride;

  const _DesktopRoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? AppColors.lavenderMid : AppColors.navy;
    final bg = (isDark ? AppColors.navySoft : AppColors.lavenderSoft)
        .withValues(alpha: 0.6);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: iconOverride ??
          Icon(icon, size: 19, color: onPressed == null ? theme.disabledColor : ink),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Hoja con el historial de himnos recientes.
class _RecentsSheet extends StatelessWidget {
  final List<Hymn> hymns;
  final FavoritesController favorites;
  final RecentHymnsController recents;
  final ValueChanged<Hymn> onSelect;

  const _RecentsSheet({
    required this.hymns,
    required this.favorites,
    required this.recents,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListenableBuilder(
        listenable: Listenable.merge([favorites, recents]),
        builder: (context, _) {
          final byNum = {for (final h in hymns) h.numero: h};
          final list = <Hymn>[
            for (final id in recents.ids) ?byNum[id],
          ];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.history, color: theme.colorScheme.secondary),
                    const SizedBox(width: 10),
                    Text('Historial', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Borrar historial',
                      onPressed: list.isEmpty ? null : recents.clear,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aún no has abierto himnos',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final hymn = list[index];
                          return ListTile(
                            leading: HymnNumberAvatar(numero: hymn.numero),
                            title: Text(
                              hymn.titulo,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(hymn.descripcionEstrofas),
                            trailing: FavoriteButton(
                              isFavorite: favorites.isFavorite(hymn.numero),
                              onPressed: () =>
                                  favorites.toggle(hymn.numero),
                            ),
                            onTap: () => onSelect(hymn),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}