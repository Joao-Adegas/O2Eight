// lib/app/app.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';
import '../widgets/connectivity_gate.dart';

class IntegradorApp extends StatefulWidget {
  const IntegradorApp({super.key});

  @override
  State<IntegradorApp> createState() => _IntegradorAppState();
}

class _IntegradorAppState extends State<IntegradorApp> {
  // O app foi desenhado no tema claro. O tema escuro será criado depois;
  // até lá, o botão de alternar tema não tem efeito visual.
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O₂Eight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: _themeMode,
      routes: buildRoutes(_toggleTheme),
      initialRoute: AppRoutes.login,
      // Cobre qualquer tela com o aviso de "sem internet" quando cair a conexão
      builder: (context, child) =>
          ConnectivityGate(child: child ?? const SizedBox.shrink()),
    );
  }
}