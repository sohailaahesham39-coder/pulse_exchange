import 'package:flutter/material.dart';
import '../../config/AppTheme.dart';

class BPStatusIndicator extends StatelessWidget {
  final int systolic;
  final int diastolic;
  final double size;

  const BPStatusIndicator({
    Key? key,
    required this.systolic,
    required this.diastolic,
    this.size = 36,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getBPStatusColor(systolic, diastolic);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Center(
        child: _getIcon(color),
      ),
    );
  }

  Widget _getIcon(Color color) {
    if (systolic >= 180 || diastolic >= 120) {
      // Hypertensive Crisis
      return Icon(
        Icons.warning_rounded,
        color: color,
        size: size * 0.5,
      );
    } else if (systolic >= 140 || diastolic >= 90) {
      // Hypertension Stage 2
      return Icon(
        Icons.error_outline,
        color: color,
        size: size * 0.5,
      );
    } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
      // Hypertension Stage 1
      return Icon(
        Icons.priority_high,
        color: color,
        size: size * 0.5,
      );
    } else if ((systolic >= 120 && systolic < 130) && diastolic < 80) {
      // Elevated
      return Icon(
        Icons.arrow_upward,
        color: color,
        size: size * 0.5,
      );
    } else {
      // Normal
      return Icon(
        Icons.check_circle_outline,
        color: color,
        size: size * 0.5,
      );
    }
  }
}