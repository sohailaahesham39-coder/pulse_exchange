import 'package:flutter/material.dart';

class AppColors {
  // Primary color palette
  static const Color primaryColor = Color(0xFFD91C5C);      // Rich rose/red
  static const Color primaryLightColor = Color(0xFFFCE4EC); // Light pinkish background
  static const Color primaryDarkColor = Color(0xFFAD1457);  // Darker rose

  // Secondary color palette
  static const Color secondaryColor = Color(0xFFF8BBD0);    // Light pink
  static const Color secondaryLightColor = Color(0xFFFFEBEE); // Very light pink
  static const Color secondaryDarkColor = Color(0xFFC2185B); // Deep pink

  // Accent color
  static const Color accentColor = Color(0xFFEC407A);       // Soft rose accent

  // Text colors
  static const Color textColor = Color(0xFF212121);         // Standard dark text
  static const Color textDarkColor = Color(0xFF000000);     // Pure black
  static const Color textLightColor = Color(0xFFFFFFFF);    // White

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);      // Green
  static const Color warningColor = Color(0xFFFFC107);      // Amber
  static const Color errorColor = Color(0xFFF44336);        // Red
  static const Color infoColor = Color(0xFF2196F3);         // Blue

  // Background colors
  static const Color backgroundColor = Color(0xFFFDFDFD);   // Off-white
  static const Color cardColor = Color(0xFFFFFFFF);         // White
  static const Color dividerColor = Color(0xFFE0E0E0);      // Light Grey

  // Shadow color
  static const Color shadowColor = Color(0x1A000000);       // Black 10% opacity

  // Additional colors
  static const Color greyColor = Color(0xFF9E9E9E);         // Grey
  static const Color lightGreyColor = Color(0xFFEEEEEE);    // Light Grey
  static const Color darkGreyColor = Color(0xFF757575);     // Dark Grey

  // BP Status colors
  static const Color normalBPColor = Color(0xFF4CAF50);     // Green
  static const Color elevatedBPColor = Color(0xFFFFEB3B);   // Yellow
  static const Color hypertensionStage1Color = Color(0xFFFF9800); // Orange
  static const Color hypertensionStage2Color = Color(0xFFF44336); // Red
  static const Color hypertensiveCrisisColor = Color(0xFF9C27B0); // Purple

  // Get color for BP status
  static Color getBPStatusColor(String status) {
    switch (status) {
      case 'normal':
        return normalBPColor;
      case 'elevated':
        return elevatedBPColor;
      case 'hypertensionStage1':
        return hypertensionStage1Color;
      case 'hypertensionStage2':
        return hypertensionStage2Color;
      case 'hypertensiveCrisis':
        return hypertensiveCrisisColor;
      default:
        return normalBPColor;
    }
  }

  // Get color for systolic/diastolic values
  static Color getBPValueColor(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return hypertensiveCrisisColor;
    } else if (systolic >= 140 || diastolic >= 90) {
      return hypertensionStage2Color;
    } else if (systolic >= 130 || diastolic >= 80) {
      return hypertensionStage1Color;
    } else if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return elevatedBPColor;
    } else {
      return normalBPColor;
    }
  }
}