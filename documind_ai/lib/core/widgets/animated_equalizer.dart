import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedEqualizer extends StatelessWidget {
  final Color color;
  final double height;
  final int barCount;

  const AnimatedEqualizer({
    super.key,
    this.color = AppTheme.neonPurple,
    this.height = 16.0,
    this.barCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          return Container(
            width: 4,
            height: height * 0.3, // initial height
            margin: EdgeInsets.only(right: index == barCount - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleY(
            begin: 1.0, 
            end: 3.0, 
            duration: Duration(milliseconds: 300 + (index * 150)),
            curve: Curves.easeInOutSine,
          );
        }),
      ),
    );
  }
}
