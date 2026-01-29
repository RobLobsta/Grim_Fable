import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GrimFableTheme {
  static ThemeData getTheme(String preset) {
    Color primaryColor;
    Color backgroundColor;
    Color accentColor;
    Color textColor = const Color(0xFFE0E0E0);
    String bodyFont;
    String displayFont;

    switch (preset) {
      case 'Abyssal':
        primaryColor = const Color(0xFF4527A0);
        backgroundColor = const Color(0xFF0D001F);
        accentColor = const Color(0xFF9575CD);
        bodyFont = 'Almendra';
        displayFont = 'Almendra';
        break;
      case 'Blood':
        primaryColor = const Color(0xFF4A0000);
        backgroundColor = const Color(0xFF1A0000);
        accentColor = const Color(0xFFFF5252);
        bodyFont = 'Crimson Pro';
        displayFont = 'Grenze Gotisch';
        break;
      case 'Emerald':
        primaryColor = const Color(0xFF003300);
        backgroundColor = const Color(0xFF001A00);
        accentColor = const Color(0xFFD4AF37); // Gold accent for Emerald
        bodyFont = 'Faustina';
        displayFont = 'Cinzel';
        break;
      default:
        primaryColor = const Color(0xFF283593);
        backgroundColor = const Color(0xFF0D1117);
        accentColor = const Color(0xFF7986CB);
        bodyFont = 'EB Garamond';
        displayFont = 'EB Garamond';
    }

    const secondaryColor = Color(0xFFF5F5F5); // Brighter for better contrast
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
        displayLarge: GoogleFonts.getFont(
          displayFont,
          color: const Color(0xFFE0E0E0),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.getFont(
          displayFont,
          color: const Color(0xFFE0E0E0),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.getFont(
          bodyFont,
          color: textColor,
          fontSize: 18,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.getFont(
          bodyFont,
          color: const Color(0xFFB0BEC5),
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.getFont(
          displayFont,
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
        labelStyle: GoogleFonts.getFont(bodyFont, color: secondaryColor),
        hintStyle: GoogleFonts.getFont(bodyFont, color: secondaryColor.withOpacity(0.4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: accentColor, width: 1.5),
          ),
          elevation: 10,
          textStyle: GoogleFonts.getFont(
            displayFont,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: accentColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.getFont(
            displayFont,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
