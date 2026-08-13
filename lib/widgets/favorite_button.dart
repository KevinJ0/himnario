import 'package:flutter/material.dart';

/// Botón de favorito con micro-animación de «pop» al tocarlo. Reutilizado en
/// el listado, el detalle y el historial para evitar duplicar la animación.
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
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
