import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configurações lidas do .env do frontend.
class AppConfig {
  AppConfig._();

  /// Endereço do backend. Padrão: http://localhost:8000
  static String get apiBaseUrl {
    final value = (dotenv.env['API_BASE_URL'] ?? '').trim();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}