import 'package:flutter/material.dart';

class GrimFableTheme {
  static ThemeData getTheme(String preset) {
    Color primaryColor;
    Color backgroundColor;
    Color accentColor;
    Color textColor = const Color(0xFFC0C0C0);

    switch (preset) {
      case 'Abyssal':
        primaryColor = const Color(0xFF004D40);
        backgroundColor = const Color(0xFF001A1A);
        accentColor = const Color(0xFF00BFA5);
        break;
      case 'Blood':
        primaryColor = const Color(0xFF4A0000);
        backgroundColor = const Color(0xFF1A0000);
        accentColor = const Color(0xFFFF5252);
        break;
      case 'Emerald':
        primaryColor = const Color(0xFF003300);
        backgroundColor = const Color(0xFF001A00);
        accentColor = const Color(0xFFD4AF37); // Gold accent for Emerald
        break;
      default:
        primaryColor = const Color(0xFF283593);
        backgroundColor = const Color(0xFF0D1117);
        accentColor = const Color(0xFF7986CB);
    }

    const secondaryColor = Color(0xFFC0C0C0);
    const surfaceColor = Color(0xFF161B22);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: secondaryColor,
        onSecondary: primaryColor,
        tertiary: accentColor,
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
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        displayMedium: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontFamily: 'Serif',
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 18,
          fontFamily: 'Serif',
          height: 1.6,
        ),
        bodyMedium: const TextStyle(
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
          borderSide: BorderSide(color: primaryColor),
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
