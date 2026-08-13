import 'package:flutter/material.dart';

import '../data/favorites_controller.dart';
import '../data/recent_hymns_controller.dart';
import '../models/hymn.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance.dart';
import '../widgets/hymn_number_avatar.dart';
import 'hymn_detail_screen.dart';

/// Pantalla con el historial de himnos abiertos recientemente, ordenados del
/// más reciente al más antiguo.
class RecentHymnsScreen extends StatefulWidget {
  final List<Hymn> himnos;
  final RecentHymnsController recents;
  final FavoritesController favorites;

  /// Prefijo base para los Hero tags; se combina con `-recents` para no
  /// chocar con los himnos del listado subyacente.
  final String heroPrefix;

  const RecentHymnsScreen({
    super.key,
    required this.himnos,
    required this.recents,
    required this.favorites,
    required this.heroPrefix,
  });

  @override
  State<RecentHymnsScreen> createState() => _RecentHymnsScreenState();
}

class _RecentHymnsScreenState extends State<RecentHymnsScreen> {
  String _heroTag(Hymn hymn) =>
      '${HymnDetailScreen.heroTag(widget.heroPrefix, hymn.numero)}-recents';

  Future<void> _openHymn(Hymn hymn) async {
    widget.recents.record(hymn.numero);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          ListenableBuilder(
            listenable: widget.recents,
            builder: (context, _) {
              return IconButton(
                tooltip: 'Borrar historial',
                onPressed: widget.recents.ids.isEmpty
                    ? null
                    : () => widget.recents.clear(),
                icon: const Icon(Icons.delete_outline),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.recents, widget.favorites]),
        builder: (context, _) {
          final byNum = {for (final h in widget.himnos) h.numero: h};
          final hymns = <Hymn>[for (final id in widget.recents.ids) ?byNum[id]];
          if (hymns.isEmpty) return _buildEmpty(Theme.of(context));
          return ListView.separated(
            itemCount: hymns.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 76, endIndent: 16),
            itemBuilder: (context, index) {
              final hymn = hymns[index];
              return _RecentHymnTile(
                hymn: hymn,
                isFavorite: widget.favorites.isFavorite(hymn.numero),
                heroTag: _heroTag(hymn),
                onTap: () => _openHymn(hymn),
                onToggleFavorite: () => widget.favorites.toggle(hymn.numero),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: EntranceFade(
        offset: const Offset(0, 0.04),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Aún no has abierto himnos',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los himnos que veas aparecerán aquí para que los encuentres rápido.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentHymnTile extends StatelessWidget {
  final Hymn hymn;
  final bool isFavorite;
  final String heroTag;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _RecentHymnTile({
    required this.hymn,
    required this.isFavorite,
    required this.heroTag,
    required this.onTap,
    required this.onToggleFavorite,
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
      trailing: IconButton(
        tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: onToggleFavorite,
      ),
      onTap: onTap,
    );
  }
}
