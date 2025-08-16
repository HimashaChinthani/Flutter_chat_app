import 'package:flutter/material.dart';

class AppTheme {
  // Updated to blue-purple gradient colors
  static const Color primaryPurple = Color(0xFF6A82FB); // blue-purple
  static const Color lightPurple = Color(0xFFA683E3);   // light purple
  static const Color darkPurple = Color(0xFF4C1D95);    // fallback dark
  static const Color accentPurple = Color(0xFFDDD6FE);
  static const Color backgroundPurple = Color(0xFFF3F4F6);

  static ThemeData get theme {
    return ThemeData(
      primarySwatch: MaterialColor(0xFF6A82FB, {
        50: Color(0xFFE3ECFF),
        100: Color(0xFFB9CDFF),
        200: Color(0xFF8EADFF),
        300: Color(0xFF638EFF),
        400: Color(0xFF4177FF),
        500: Color(0xFF2060FF),
        600: Color(0xFF1C56E6),
        700: Color(0xFF184BCC),
        800: Color(0xFF1441B3),
        900: Color(0xFF103799),
      }),
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
