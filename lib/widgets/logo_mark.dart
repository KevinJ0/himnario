import 'package:flutter/material.dart';

class LogoMark extends StatelessWidget {
  final double size;
  final bool rounded;

  const LogoMark({super.key, this.size = 96, this.rounded = true});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rounded ? size * 0.22 : 0),
      child: Image.asset(
        'assets/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}