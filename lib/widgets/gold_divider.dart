import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GoldDivider extends StatelessWidget {
  final double height;
  final Color? color;

  const GoldDivider({super.key, this.height = 12, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        color ?? AppColors.gold.withValues(alpha: isDark ? 0.55 : 0.5);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: lineColor)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.6),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: height * 0.28,
                height: height * 0.28,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: lineColor)),
        ],
      ),
    );
  }
}
