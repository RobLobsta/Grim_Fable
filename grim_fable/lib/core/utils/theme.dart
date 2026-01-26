import 'package:flutter/material.dart';

class GrimFableTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A237E), // Dark Blue
        brightness: Brightness.dark,
        primary: const Color(0xFF1A237E),
        secondary: const Color(0xFFC0C0C0), // Silver
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117), // Very dark blue/black
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFE0E0E0), // Light silver
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFC0C0C0), // Silver
          fontSize: 18,
          fontFamily: 'Serif',
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Color(0xFFC0C0C0),
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Serif',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC0C0C0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A237E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC0C0C0), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFC0C0C0), fontFamily: 'Serif'),
        hintStyle: TextStyle(color: const Color(0xFFC0C0C0).withOpacity(0.5), fontFamily: 'Serif'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: const Color(0xFFC0C0C0),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
      ),
    );
  }
}
