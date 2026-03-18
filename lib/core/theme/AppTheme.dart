import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary color palette - Vibrant Fitness Theme (Royal Blue / Cyan)
  static const Color primaryColor = Color(0xFF2962FF);      // Vibrant Blue
  static const Color primaryLightColor = Color(0xFFE3F2FD); // Light Blue background
  static const Color primaryDarkColor = Color(0xFF0D47A1);  // Deep Blue
  
  // Secondary color palette - Modern Dark/Grey
  static const Color secondaryColor = Color(0xFF263238);    // Blue Grey
  static const Color secondaryLightColor = Color(0xFFECEFF1); // Very light grey
  static const Color secondaryDarkColor = Color(0xFF102027); // Deepest grey

  // Accent color - Energizing Orange/Coral
  static const Color accentColor = Color(0xFFFF6D00);       // Vibrant Orange accent

  // Text colors
  static const Color textColor = Color(0xFF1A1A1A);         // Deep charcoal
  static const Color textDarkColor = Color(0xFF000000);     // Pure black
  static const Color textLightColor = Color(0xFFFFFFFF);    // White

  // Status colors
  static const Color successColor = Color(0xFF00C853);      // Vibrant Green
  static const Color warningColor = Color(0xFFFFAB00);      // Amber
  static const Color errorColor = Color(0xFFFF1744);        // Bright Red
  static const Color infoColor = Color(0xFF00B0FF);         // Sky Blue

  // Background colors
  static const Color backgroundColor = Color(0xFFF8F9FA);   // Modern light grey
  static const Color cardColor = Color(0xFFFFFFFF);         // White
  static const Color dividerColor = Color(0xFFEEEEEE);      // Light Grey

  // Shadow color
  static const Color shadowColor = Color(0x33000000);       // Black 20% opacity

  // Additional colors
  static const Color greyColor = Color(0xFF9E9E9E);         // Standard Grey
  static const Color lightGreyColor = Color(0xFFF5F5F5);    // Very Light Grey
  static const Color darkGreyColor = Color(0xFF616161);     // Dark Grey

  // Health Stats colors
  static const Color heartRateColor = Color(0xFFFF1744);    // Red
  static const Color stepsColor = Color(0xFF00E676);        // Green
  static const Color caloriesColor = Color(0xFFFF9100);     // Orange
  static const Color sleepColor = Color(0xFF651FFF);        // Purple

  // Helper method to get success color based on theme
  static Color getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? successColor
        : successColor.withOpacity(0.8);
  }

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      background: backgroundColor,
      surface: cardColor,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 26),
      displaySmall: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 22),
      headlineMedium: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
      headlineSmall: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: GoogleFonts.outfit(color: textColor, fontSize: 16),
      bodyMedium: GoogleFonts.outfit(color: darkGreyColor, fontSize: 14),
      titleMedium: GoogleFonts.outfit(color: textColor, fontSize: 16),
      titleSmall: GoogleFonts.outfit(color: greyColor, fontSize: 14),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: textLightColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorColor),
      ),
      labelStyle: const TextStyle(color: greyColor),
      hintStyle: TextStyle(color: greyColor.withOpacity(0.5)),
    ),
    appBarTheme: AppBarTheme(
      color: backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.outfit(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: greyColor,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      type: BottomNavigationBarType.fixed,
      elevation: 20,
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 6,
      shadowColor: shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Color(0xFF0F172A), // Slate 900
    cardColor: Color(0xFF1E293B), // Slate 800
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(color: textLightColor, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.outfit(color: textLightColor, fontWeight: FontWeight.bold, fontSize: 26),
      displaySmall: GoogleFonts.outfit(color: textLightColor, fontWeight: FontWeight.bold, fontSize: 22),
      headlineMedium: GoogleFonts.outfit(color: textLightColor, fontWeight: FontWeight.bold, fontSize: 20),
      bodyLarge: GoogleFonts.outfit(color: textLightColor, fontSize: 16),
      bodyMedium: GoogleFonts.outfit(color: lightGreyColor, fontSize: 14),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    elevatedButtonTheme: lightTheme.elevatedButtonTheme,
    outlinedButtonTheme: lightTheme.outlinedButtonTheme,
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: Color(0xFF1E293B),
    ),
    appBarTheme: lightTheme.appBarTheme.copyWith(
      color: Color(0xFF0F172A),
      titleTextStyle: lightTheme.appBarTheme.titleTextStyle?.copyWith(color: textLightColor),
      iconTheme: const IconThemeData(color: textLightColor),
    ),
    cardTheme: lightTheme.cardTheme.copyWith(
      color: Color(0xFF1E293B),
    ),
  );
}