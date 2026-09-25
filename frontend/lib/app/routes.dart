// lib/app/routes.dart
import 'package:flutter/widgets.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/form/intake_form_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/signup/signup_screen.dart';

class AppRoutes {
  static const login = '/';
  static const signup = '/signup';
  static const form = '/form';
  static const home = '/home';
  static const chat = '/chat';
}

Map<String, WidgetBuilder> buildRoutes(VoidCallback onToggleTheme) {
  return {
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.signup: (_) => const SignUpScreen(),
    AppRoutes.form: (_) => const IntakeFormScreen(),
    AppRoutes.home: (_) => HomeScreen(onToggleTheme: onToggleTheme),
    AppRoutes.chat: (_) => const ChatScreen(),
  };
}