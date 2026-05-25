import 'package:flutter/widgets.dart';
import '../screens/form/intake_form_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';

class AppRoutes {
  static const login = '/';
  static const form = '/form';
  static const home = '/home';
}

Map<String, WidgetBuilder> buildRoutes(VoidCallback onToggleTheme) {
  return {
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.form: (_) => const IntakeFormScreen(),
    AppRoutes.home: (_) => HomeScreen(onToggleTheme: onToggleTheme),
  };
}
