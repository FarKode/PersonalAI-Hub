import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.amoledBlack,
            Color(0xFF0F172A), // Very dark slate blue
            Color(0xFF161026), // Very dark purple tint
            AppTheme.amoledBlack,
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
      ),
      child: child,
    );
  }
}
