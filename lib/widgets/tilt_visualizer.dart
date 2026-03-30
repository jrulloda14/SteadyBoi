// lib/widgets/tilt_visualizer.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

class TiltVisualizer extends StatelessWidget {
  final double angleDeg;

  const TiltVisualizer({super.key, required this.angleDeg});

  @override
  Widget build(BuildContext context) {
    final clamped = angleDeg.clamp(-40.0, 40.0);
    final rad = clamped * math.pi / 180.0;
    final abs = angleDeg.abs();

    Color bodyColor;
    if (abs > 45) {
      bodyColor = AppTheme.warn;
    } else if (abs < 5) {
      bodyColor = AppTheme.green;
    } else {
      bodyColor = AppTheme.accent;
    }

    return SizedBox(
      width: 56,
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Center(
              child: Transform.rotate(
                angle: rad,
                alignment: Alignment.bottomCenter,
                child: _RobotBody(color: bodyColor),
              ),
            ),
          ),
          Container(
            width: 56,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotBody extends StatelessWidget {
  final Color color;
  const _RobotBody({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withAlpha(100)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(180)),
        boxShadow: [BoxShadow(color: color.withAlpha(60), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 7),
          Center(
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(180),
                boxShadow: [BoxShadow(color: color, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
