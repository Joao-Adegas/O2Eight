import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class IntegradorApp extends StatefulWidget {
  const IntegradorApp({super.key});

  @override
  State<IntegradorApp> createState() => _IntegradorAppState();
}

class _IntegradorAppState extends State<IntegradorApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto Integrador',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routes: buildRoutes(_toggleTheme),
      initialRoute: AppRoutes.login,
    );
  }
}