import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1); // Indigo 500
  static const Color secondaryColor = Color(0xFF8B5CF6); // Violet 500
  static const Color backgroundColor = Color(0xFFF9FAFB); // Gray 50
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF111827); // Gray 900
  static const Color textSecondaryColor = Color(0xFF6B7280); // Gray 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimaryColor, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(color: textPrimaryColor, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.poppins(color: textPrimaryColor),
        bodyMedium: GoogleFonts.poppins(color: textSecondaryColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
