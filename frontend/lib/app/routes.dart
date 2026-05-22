import 'package:flutter/widgets.dart';
import '../screens/home/home_screen.dart';

class AppRoutes {
  static const home = '/';
}

Map<String, WidgetBuilder> buildRoutes(VoidCallback onToggleTheme) {
  return {
    AppRoutes.home: (_) => HomeScreen(onToggleTheme: onToggleTheme),
  };
}
