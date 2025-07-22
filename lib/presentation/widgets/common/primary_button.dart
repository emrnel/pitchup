// lib/presentation/widgets/common/primary_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = isEnabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isButtonEnabled ? AppColors.primaryColor : AppColors.dividerColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          ),
          elevation: isButtonEnabled ? 2 : 0,
          shadowColor: AppColors.primaryColor.withOpacity(0.3),
        ),
        onPressed: isButtonEnabled ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: AppTypography.buttonText,
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: AppTypography.buttonText,
                  ),
      ),
    );
  }
}