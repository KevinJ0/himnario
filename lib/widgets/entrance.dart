import 'package:flutter/material.dart';

/// Entrada elegante (fade + deslizamiento) para elementos que aparecen en
/// pantalla. Se reproduce una sola vez cuando el widget se monta.
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;

  const EntranceFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.06),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
