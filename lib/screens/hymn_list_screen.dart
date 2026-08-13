import 'package:alphabet_list_view/alphabet_list_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/favorites_controller.dart';
import '../data/recent_hymns_controller.dart';
import '../models/hymn.dart';
import '../services/hymn_search.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance.dart';
import '../widgets/favorite_button.dart';
import '../widgets/hymn_number_avatar.dart';
import '../widgets/logo_mark.dart';
import 'hymn_detail_screen.dart';
import 'recent_hymns_screen.dart';

enum _HymnOrder { numero, titulo }

class HymnListScreen extends StatefulWidget {
  final List<Hymn> himnos;
  final FavoritesController favorites;
  final RecentHymnsController? recents;
  final bool showFavoritesOnly;
  final String title;
  final VoidCallback onThemeChanged;

  /// Prefijo que hace únicos los Hero tags: el listado general y el de
  /// favoritos coexisten en el árbol (IndexedStack), así un mismo himno en
  /// ambas pestañas no debe compartir tag.
  final String heroPrefix;

  const HymnListScreen({
    super.key,
    required this.himnos,
    required this.favorites,
    this.recents,
    required this.showFavoritesOnly,
    required this.title,
    required this.onThemeChanged,
    this.heroPrefix = 'todos',
  });

  @override
  State<HymnListScreen> createState() => _HymnListScreenState();
}

/// Barra de búsqueda y filtro que colapsa siguiendo el scroll. Se reconstruye
/// solo a sí misma mediante `AnimatedBuilder`, sin reconstruir la lista, por lo
/// que el arrastre no genera lag.
class _CollapsingSearchBar extends StatelessWidget {
  const _CollapsingSearchBar({
    required this.animation,
    required this.expandedHeight,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onQueryCleared,
    required this.order,
    required this.onOrderChanged,
  });

  final Animation<double> animation;
  final double expandedHeight;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onQueryCleared;
  final _HymnOrder order;
  final ValueChanged<_HymnOrder> onOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final height = animation.value;
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: expandedHeight == 0 ? 0 : height / expandedHeight,
                child: SizedBox(
                  width: double.infinity,
                  height: expandedHeight,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: 'Buscar por número o título',
                                prefixIcon: const Icon(Icons.search),
                                isDense: true,
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Limpiar búsqueda',
                                        icon: const Icon(Icons.clear),
                                        onPressed: onQueryCleared,
                                      ),
                              ),
                              onChanged: onQueryChanged,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: SegmentedButton<_HymnOrder>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: _HymnOrder.numero,
                                  label: Text('Por número'),
                                ),
                                ButtonSegment(
                                  value: _HymnOrder.titulo,
                                  label: Text('Alfabético'),
                                ),
                              ],
                              selected: {order},
                              onSelectionChanged: (selection) {
                                onOrderChanged(selection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HymnListScreenState extends State<HymnListScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _searchBarController;
  late final Animation<double> _searchBarHeight;
  String _query = '';
  _HymnOrder _order = _HymnOrder.numero;
  final _searchController = TextEditingController();
  double _lastScrollOffset = 0;
  bool _entranceLocked = false;

  /// Títulos normalizados por número, calculados una sola vez.
  late Map<int, String> _normMap;

  /// Memoria para el listado filtrado/ordenado: solo se recalcula cuando
  /// cambian la búsqueda, el orden, los favoritos o el origen.
  List<Hymn>? _cachedFiltered;
  String _cacheQuery = '';
  _HymnOrder _cacheOrder = _HymnOrder.numero;
  Set<int> _cacheFavorites = const {};
  List<Hymn>? _cacheSource;
  bool _cacheShowFavoritesOnly = false;

  static const double _searchBarExpandedHeight = 118;

  @override
  void initState() {
    super.initState();
    _normMap = _buildNormMap(widget.himnos);
    _searchBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
    _searchBarHeight = Tween<double>(
      begin: 0,
      end: _searchBarExpandedHeight,
    ).animate(_searchBarController);
  }

  @override
  void didUpdateWidget(covariant HymnListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.himnos, widget.himnos)) {
      _normMap = _buildNormMap(widget.himnos);
      _invalidateFilteredCache();
    }
  }

  Map<int, String> _buildNormMap(List<Hymn> himnos) {
    return HymnSearch.buildNormMap(himnos);
  }

  void _invalidateFilteredCache() {
    _cachedFiltered = null;
    _cacheSource = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchBarController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Distancia de scroll (px) necesaria para ocultar del todo la barra.
  static const double _collapsePullDistance = 150;

  /// Sigue al dedo: cada pixel de scroll abajo reduce la altura de la barra de
  /// manera proporcional (como si la estuvieras halando hacia arriba) y cada
  /// pixel de scroll arriba la vuelve a mostrar.
  bool _onScrollNotification(ScrollNotification notification) {
    if (!_entranceLocked) {
      _entranceLocked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    if (notification is ScrollStartNotification) {
      _lastScrollOffset = notification.metrics.pixels;
    } else if (notification is ScrollUpdateNotification) {
      final offset = notification.metrics.pixels;
      final delta = offset - _lastScrollOffset;
      _lastScrollOffset = offset;
      final next = offset <= 0
          ? 1.0
          : _searchBarController.value - delta / _collapsePullDistance;
      _searchBarController.value = next.clamp(0.0, 1.0);
    } else if (notification is ScrollEndNotification) {
      _settleSearchBar();
    }
    return false;
  }

  /// Al soltar, la barra se asienta hacia la posición más cercana (oculta o
  /// visible) con una pequeña animación.
  void _settleSearchBar() {
    final target = _searchBarController.value >= 0.5 ? 1.0 : 0.0;
    _searchBarController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Envuelve un elemento con la animación de entrada solo durante la carga
  /// inicial. Tras el primer desplazamiento se bloquean para que los saltos
  /// por letra o el scroll rápido no se vean entrecortados.
  Widget _itemEntrance(int index, Widget tile) {
    if (_entranceLocked) return tile;
    return EntranceFade(
      delay: Duration(milliseconds: index < 12 ? index * 40 : 0),
      child: tile,
    );
  }

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  List<Hymn> get _filtered {
    final query = _query.trim().toLowerCase();
    final favIds = widget.favorites.ids;
    if (_cachedFiltered != null &&
        query == _cacheQuery &&
        _order == _cacheOrder &&
        identical(_cacheSource, widget.himnos) &&
        _cacheShowFavoritesOnly == widget.showFavoritesOnly &&
        setEquals(_cacheFavorites, favIds)) {
      return _cachedFiltered!;
    }
    final filtered = HymnSearch.filter(
      source: widget.himnos,
      normMap: _normMap,
      query: query,
      showFavoritesOnly: widget.showFavoritesOnly,
      favoriteIds: favIds,
      sortAlphabetically: _order == _HymnOrder.titulo,
    );
    _cacheQuery = query;
    _cacheOrder = _order;
    _cacheFavorites = favIds;
    _cacheSource = widget.himnos;
    _cacheShowFavoritesOnly = widget.showFavoritesOnly;
    _cachedFiltered = filtered;
    return filtered;
  }

  /// Hero tag único para cada himno, compartido con el detalle.
  String _heroTag(Hymn hymn) =>
      HymnDetailScreen.heroTag(widget.heroPrefix, hymn.numero);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.recents != null)
            IconButton(
              tooltip: 'Historial',
              icon: const Icon(Icons.history),
              onPressed: _openRecents,
            ),
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      body: Column(
        children: [
          _CollapsingSearchBar(
            animation: _searchBarHeight,
            expandedHeight: _searchBarExpandedHeight,
            controller: _searchController,
            query: _query,
            onQueryChanged: (value) {
              setState(() => _query = value);
            },
            onQueryCleared: _clearQuery,
            order: _order,
            onOrderChanged: (selection) {
              setState(() => _order = selection);
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            },
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.favorites,
        if (widget.recents != null) widget.recents!,
      ]),
      builder: (context, _) {
        final filtered = _filtered;
        if (filtered.isEmpty) {
          return _buildEmptyState(theme);
        }
        final Widget list;
        if (_order == _HymnOrder.titulo) {
          list = _buildAlphabeticList(filtered, theme);
        } else {
          list = LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 600;
              final core = useGrid
                  ? GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.4,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final hymn = filtered[index];
                        return _itemEntrance(
                          index,
                          _HymnGridTile(
                            hymn: hymn,
                            isFavorite: widget.favorites.isFavorite(
                              hymn.numero,
                            ),
                            heroTag: _heroTag(hymn),
                            onTap: () => _openHymn(hymn),
                            onToggleFavorite: () =>
                                widget.favorites.toggle(hymn.numero),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, indent: 76, endIndent: 16),
                      itemBuilder: (context, index) {
                        final hymn = filtered[index];
                        return _itemEntrance(
                          index,
                          _HymnListTile(
                            hymn: hymn,
                            isFavorite: widget.favorites.isFavorite(
                              hymn.numero,
                            ),
                            heroTag: _heroTag(hymn),
                            onTap: () => _openHymn(hymn),
                            onToggleFavorite: () =>
                                widget.favorites.toggle(hymn.numero),
                          ),
                        );
                      },
                    );
              return _inListShell(core);
            },
          );
        }
        return list;
      },
    );
  }

  /// Envoltura común de la lista principal (scrollbar + colapso de búsqueda).
  Widget _inListShell(Widget core) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Scrollbar(
          thumbVisibility: true,
          controller: _scrollController,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: core,
          ),
        ),
      ),
    );
  }

  /// Listado alfabético con `AlphabetListView`: agrupa los himnos por la
  /// primera letra normalizada del título y delega el sidebar, los headers
  /// fijos, el salto por letra y la letra activa al paquete.
  Widget _buildAlphabeticList(List<Hymn> filtered, ThemeData theme) {
    final groups = <String, List<Hymn>>{};
    for (final hymn in filtered) {
      final letter = HymnSearch.groupLetter(_normMap[hymn.numero]!);
      groups.putIfAbsent(letter, () => []).add(hymn);
    }
    final symbols = [
      for (final letter in kAlphabetOrder)
        if (groups.containsKey(letter)) letter,
      if (groups.containsKey('#')) '#',
    ];
    var index = 0;
    final items = [
      for (final letter in symbols)
        AlphabetListViewItemGroup(
          tag: letter,
          children: [
            for (final hymn in groups[letter]!)
              _itemEntrance(
                index++,
                _HymnListTile(
                  hymn: hymn,
                  isFavorite: widget.favorites.isFavorite(hymn.numero),
                  heroTag: _heroTag(hymn),
                  onTap: () => _openHymn(hymn),
                  onToggleFavorite: () => widget.favorites.toggle(hymn.numero),
                ),
              ),
          ],
        ),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Scrollbar(
          thumbVisibility: true,
          controller: _scrollController,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: AlphabetListView(
              scrollController: _scrollController,
              items: items,
              options: AlphabetListViewOptions(
                listOptions: ListOptions(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  listHeaderBuilder: (context, symbol) =>
                      _SectionHeader(symbol: symbol),
                ),
                scrollbarOptions: ScrollbarOptions(
                  symbols: symbols,
                  width: 36,
                  symbolBuilder: (context, symbol, state) =>
                      _SidebarSymbol(symbol: symbol, state: state),
                ),
                overlayOptions: OverlayOptions(
                  overlayBuilder: (context, symbol) =>
                      _LetterOverlay(symbol: symbol),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final title = widget.showFavoritesOnly
        ? 'Aún no tienes favoritos'
        : 'No se encontraron himnos.';
    final subtitle = widget.showFavoritesOnly
        ? 'Toca el corazón en un himno para guardarlo aquí.'
        : null;
    return Center(
      child: EntranceFade(
        offset: const Offset(0, 0.05),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoMark(size: 88),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHymn(Hymn hymn) async {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.recents?.record(hymn.numero);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HymnDetailScreen(
          hymn: hymn,
          favorites: widget.favorites,
          heroPrefix: widget.heroPrefix,
        ),
      ),
    );
  }

  Future<void> _openRecents() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final recents = widget.recents;
    if (recents == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecentHymnsScreen(
          himnos: widget.himnos,
          recents: recents,
          favorites: widget.favorites,
          heroPrefix: widget.heroPrefix,
        ),
      ),
    );
  }
}

class _HymnListTile extends StatelessWidget {
  final Hymn hymn;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String heroTag;

  const _HymnListTile({
    required this.hymn,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Hero(
        tag: heroTag,
        child: HymnNumberAvatar(numero: hymn.numero),
      ),
      title: Text(
        hymn.titulo,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: AppFonts.display,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        hymn.descripcionEstrofas,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: FavoriteButton(
        isFavorite: isFavorite,
        onPressed: onToggleFavorite,
      ),
      onTap: onTap,
    );
  }
}

class _HymnGridTile extends StatelessWidget {
  final Hymn hymn;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final String heroTag;

  const _HymnGridTile({
    required this.hymn,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: heroTag,
                child: HymnNumberAvatar(
                  numero: hymn.numero,
                  style: HymnAvatarStyle.grid,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hymn.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hymn.descripcionEstrofas,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

class _SectionHeader extends StatelessWidget {
  final String symbol;

  const _SectionHeader({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      color: theme.colorScheme.primary,
      child: Text(
        symbol,
        style: theme.textTheme.labelLarge?.copyWith(
          fontFamily: AppFonts.display,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarSymbol extends StatelessWidget {
  final String symbol;
  final AlphabetScrollbarItemState state;

  const _SidebarSymbol({required this.symbol, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (state) {
      AlphabetScrollbarItemState.active => theme.colorScheme.primary,
      AlphabetScrollbarItemState.inactive => theme.colorScheme.onSurfaceVariant,
      AlphabetScrollbarItemState.deactivated =>
        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
    };
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        style: TextStyle(
          fontSize: state == AlphabetScrollbarItemState.active ? 13 : 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: AppFonts.body,
        ),
        child: Text(symbol),
      ),
    );
  }
}

class _LetterOverlay extends StatelessWidget {
  final String symbol;

  const _LetterOverlay({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        symbol,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
