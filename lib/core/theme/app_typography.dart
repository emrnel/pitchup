import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
// Font Families
  static const String headingFont = 'Montserrat';
  static const String bodyFont = 'Roboto';
// Font Sizes
  static const double h1Size = 32.0;
  static const double h2Size = 24.0;
  static const double h3Size = 20.0;
  static const double h4Size = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double caption = 10.0;
// Font Weights
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
// Text Styles
  static TextStyle h1 = const TextStyle(
    fontFamily: headingFont,
    fontSize: h1Size,
    fontWeight: fontBold,
    color: AppColors.textPrimary,
  );

  static TextStyle h2 = const TextStyle(
    fontFamily: headingFont,
    fontSize: h2Size,
    fontWeight: fontSemiBold,
    color: AppColors.textPrimary,
  );

  static TextStyle h3 = const TextStyle(
    fontFamily: headingFont,
    fontSize: h3Size,
    fontWeight: fontSemiBold,
    color: AppColors.textPrimary,
  );

  static TextStyle h4 = const TextStyle(
    fontFamily: headingFont,
    fontSize: h4Size,
    fontWeight: fontMedium,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLargeText = const TextStyle(
    fontFamily: bodyFont,
    fontSize: bodyLarge,
    fontWeight: fontRegular,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMediumText = const TextStyle(
    fontFamily: bodyFont,
    fontSize: bodyMedium,
    fontWeight: fontRegular,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmallText = const TextStyle(
    fontFamily: bodyFont,
    fontSize: bodySmall,
    fontWeight: fontRegular,
    color: AppColors.textTertiary,
  );

  static TextStyle captionText = const TextStyle(
    fontFamily: bodyFont,
    fontSize: caption,
    fontWeight: fontRegular,
    color: AppColors.textTertiary,
  );

  static TextStyle buttonText = const TextStyle(
    fontFamily: headingFont,
    fontSize: bodyLarge,
    fontWeight: fontMedium,
    color: Colors.white,
  );
}
