import 'package:flutter/material.dart';

class GrimFableTheme {
  static const primaryColor = Color(0xFF1A237E);
  static const secondaryColor = Color(0xFFC0C0C0);
  static const backgroundColor = Color(0xFF0D1117);
  static const surfaceColor = Color(0xFF161B22);
  static const accentColor = Color(0xFF5C6BC0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: secondaryColor,
        onSecondary: primaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFE0E0E0),
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        displayMedium: TextStyle(
          color: Color(0xFFE0E0E0),
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: secondaryColor,
          fontSize: 18,
          fontFamily: 'Serif',
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 16,
          fontFamily: 'Serif',
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Serif',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: secondaryColor,
          letterSpacing: 2.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: secondaryColor, fontFamily: 'Serif'),
        hintStyle: TextStyle(color: secondaryColor.withOpacity(0.4), fontFamily: 'Serif'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: secondaryColor, width: 0.5),
          ),
          elevation: 10,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
