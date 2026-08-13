import 'package:flutter/material.dart';

import '../data/favorites_controller.dart';
import '../data/hymn_repository.dart';
import '../data/recent_hymns_controller.dart';
import '../models/hymn.dart';
import '../widgets/entrance.dart';
import '../widgets/loading_skeleton.dart';
import 'desktop_hymn_layout.dart';
import 'hymn_list_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const MainScreen({super.key, required this.onThemeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _favorites = FavoritesController();
  final _recents = RecentHymnsController();
  List<Hymn>? _himnos;
  Object? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _favorites.load();
    _recents.load();
    _loadHimnos();
  }

  Future<void> _loadHimnos() async {
    try {
      final himnos = await HymnRepository.load();
      if (!mounted) return;
      setState(() => _himnos = himnos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null || _himnos == null) {
      return _buildTab(
        showFavoritesOnly: false,
        title: 'Himnos de Gloria y Triunfo',
        heroPrefix: 'todos',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas anchas (≥ 900px) se usa el panel dividido tipo
        // escritorio; por debajo, el flujo móvil con barra de navegación.
        final wide = constraints.maxWidth > 900;
        return Scaffold(
          body: wide
              ? DesktopHymnLayout(
                  himnos: _himnos!,
                  favorites: _favorites,
                  recents: _recents,
                  onThemeChanged: widget.onThemeChanged,
                )
              : IndexedStack(
                  index: _tab,
                  children: [
                    _buildTab(
                      showFavoritesOnly: false,
                      title: 'Himnos de Gloria y Triunfo',
                      heroPrefix: 'todos',
                    ),
                    _buildTab(
                      showFavoritesOnly: true,
                      title: 'Favoritos',
                      heroPrefix: 'favoritos',
                    ),
                  ],
                ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _tab = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book),
                      label: 'Himnos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Favoritos',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTab({
    required bool showFavoritesOnly,
    required String title,
    required String heroPrefix,
  }) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: EntranceFade(
            offset: const Offset(0, 0.04),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('No se pudieron cargar los himnos'),
                  const SizedBox(height: 8),
                  Text('$_error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadHimnos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_himnos == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const LoadingSkeleton(),
      );
    }
    return HymnListScreen(
      himnos: _himnos!,
      favorites: _favorites,
      recents: _recents,
      showFavoritesOnly: showFavoritesOnly,
      title: title,
      onThemeChanged: widget.onThemeChanged,
      heroPrefix: heroPrefix,
    );
  }
}
