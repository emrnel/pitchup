// lib/presentation/widgets/common/loading_indicator.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final bool overlay;

  const LoadingIndicator({
    Key? key,
    this.size = 32.0,
    this.color,
    this.overlay = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primaryColor,
        strokeWidth: 2,
      ),
    );

    if (overlay) {
      return Container(
        color: Colors.black54,
        child: Center(child: indicator),
      );
    }

    return indicator;
  }
}