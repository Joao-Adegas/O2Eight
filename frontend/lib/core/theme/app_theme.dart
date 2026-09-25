import 'package:flutter/material.dart';

/// Tema central do app — cores, gradientes e ThemeData (light/dark).
/// Outros widgets (ex: GradientButton) referenciam AppTheme.accentStart /
/// AppTheme.accentEnd, então os nomes abaixo precisam ser mantidos
/// caso você queira renomear.
class AppTheme {
  AppTheme._(); // evita instanciar a classe

  // Cores base do gradiente usado nos botões e no header da Home
  static const Color accentStart = Color(0xFF2ECFCF);
  static const Color accentEnd = Color(0xFF0D4F7C);
  static const Color accentMid = Color(0xFF1A7FA8);

  // Cores de apoio
  static const Color darkBackground = Color(0xFF0B1F3A);
  static const Color lightBackground = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentStart, accentMid, accentEnd],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentEnd,
        brightness: Brightness.light,
      ),
      fontFamily: 'Poppins',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentEnd,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Poppins',
    );
  }
}