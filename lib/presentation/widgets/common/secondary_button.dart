// lib/presentation/widgets/common/secondary_button.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;

  const SecondaryButton({
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
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isButtonEnabled ? AppColors.primaryColor : AppColors.textTertiary,
          side: BorderSide(
            color: isButtonEnabled
                ? AppColors.primaryColor
                : AppColors.dividerColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          ),
        ),
        onPressed: isButtonEnabled ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
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
                        style: AppTypography.buttonText.copyWith(
                          color: isButtonEnabled
                              ? AppColors.primaryColor
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: AppTypography.buttonText.copyWith(
                      color: isButtonEnabled
                          ? AppColors.primaryColor
                          : AppColors.textTertiary,
                    ),
                  ),
      ),
    );
  }
}