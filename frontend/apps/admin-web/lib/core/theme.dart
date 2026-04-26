import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3F6FF),
    primaryColor: const Color(0xFF3D5AFE),
    cardColor: Colors.white,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3D5AFE),
      secondary: Color(0xFF00B8D4),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0F1A),
    primaryColor: const Color(0xFF7C4DFF),
    cardColor: const Color(0xFF121826),
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C4DFF),
      secondary: Color(0xFF00E5FF),
    ),
    useMaterial3: true,
  );
}

