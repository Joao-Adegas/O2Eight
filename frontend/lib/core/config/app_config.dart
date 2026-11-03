// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configurações lidas do .env do frontend.
class AppConfig {
  AppConfig._();

  /// API publicada. Usada quando o .env não define API_BASE_URL.
  static const _defaultApiBaseUrl = 'https://o2eight.onrender.com';

  /// Endereço do backend.
  /// Para usar a API local, coloque no .env: API_BASE_URL=http://localhost:8000
  static String get apiBaseUrl {
    final value = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final url = value.isEmpty ? _defaultApiBaseUrl : value;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}