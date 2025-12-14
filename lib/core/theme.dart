import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Neumorphism Colors - Soft & Pleasant (Low brightness)
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFFEC4899); // Pink
  static const Color accentColor = Color(0xFFF59E0B); // Orange
  static const Color backgroundColor = Color(0xFFF0F0F0); // Dimmer Gray (low brightness, easy on eyes)
  static const Color surfaceColor = Color(0xFFF0F0F0); // Dimmer Gray
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFFBBF24); // Yellow
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // 🌟 Neumorphism Shadow Colors
  static const Color lightShadow = Color(0xFFFFFFFF); // White highlight
  static const Color darkShadow = Color(0xFFD0D0D0); // Soft shadow

  // 📝 Text Colors (High contrast for accessibility)
  static const Color textPrimary = Color(0xFF1A1A1A); // Very Dark Gray (better contrast)
  static const Color textSecondary = Color(0xFF5A5A5A); // Medium Gray

  // 🎨 Neumorphism Box Shadow
  static List<BoxShadow> get neumorphicShadow => [
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

  // 🎨 Pressed Neumorphism (Inset)
  static List<BoxShadow> get neumorphicShadowInset => [
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        error: errorColor,
        brightness: Brightness.light,
      ),

      // Typography
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      
      // Card Theme (Neumorphism style)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
        prefixIconColor: textSecondary,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceColor,
          foregroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Chips (for time slots)
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(color: textPrimary),
        secondaryLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        checkmarkColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),
      
      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.outfit(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.all(
          const IconThemeData(color: textSecondary),
        ),
      ),
    );
  }
}
