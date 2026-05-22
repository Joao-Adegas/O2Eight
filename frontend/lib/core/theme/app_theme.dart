import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0B1F3A);
  static const Color darkSurface = Color(0xFF102845);
  static const Color darkBorder = Color(0x263CCCB4);
  static const Color darkText = Color(0xFFE8F0FB);
  static const Color darkMuted = Color(0xFF7A9CC4);

  static const Color lightBg = Color(0xFFF0F4F8);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0x1F143B74);
  static const Color lightText = Color(0xFF143B74);
  static const Color lightMuted = Color(0xFF5A7A9E);

  static const Color accentStart = Color(0xFF3CCCB4);
  static const Color accentEnd = Color(0xFF0780AE);

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      colorScheme: base.colorScheme.copyWith(
        primary: accentStart,
        secondary: accentEnd,
        surface: lightSurface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: lightBorder),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: base.colorScheme.copyWith(
        primary: accentStart,
        secondary: accentEnd,
        surface: darkSurface,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
