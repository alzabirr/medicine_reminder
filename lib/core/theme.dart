import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Neumorphism Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color backgroundColor = Color(0xFFF0F0F0);
  static const Color surfaceColor = Color(0xFFF0F0F0);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color darkShadow = Color(0xFFD0D0D0);

  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  // 🎨 Dynamic shadows
  static List<BoxShadow> getNeumorphicShadow(BuildContext context) {
    return [
      const BoxShadow(
        color: lightShadow,
        offset: Offset(-6, -6),
        blurRadius: 12,
        spreadRadius: 0,
      ),
      const BoxShadow(
        color: darkShadow,
        offset: Offset(6, 6),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> getNeumorphicShadowInset(BuildContext context) {
    return [
      const BoxShadow(
        color: darkShadow,
        offset: Offset(-4, -4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      const BoxShadow(
        color: lightShadow,
        offset: Offset(4, 4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];
  }

  // Legacy static getters for backward compatibility
  static List<BoxShadow> get neumorphicShadow => [
    const BoxShadow(color: lightShadow, offset: Offset(-6, -6), blurRadius: 12),
    const BoxShadow(color: darkShadow, offset: Offset(6, 6), blurRadius: 12),
  ];

  static List<BoxShadow> get neumorphicShadowInset => [
    const BoxShadow(color: darkShadow, offset: Offset(-4, -4), blurRadius: 8),
    const BoxShadow(color: lightShadow, offset: Offset(4, 4), blurRadius: 8),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),

      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.4)),
        prefixIconColor: textSecondary,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        actionTextColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        iconTheme: WidgetStateProperty.all(const IconThemeData(color: textSecondary)),
      ),
    );
  }
}
