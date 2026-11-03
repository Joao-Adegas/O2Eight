// lib/services/progress_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/core/config/app_config.dart';

class ProgressService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Dias sem fumar, dinheiro economizado, custo diário.
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/progress/dashboard'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Falha ao carregar progresso (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
      );
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Recaída: zera o contador de dias sem fumar.
  Future<void> markSmoked() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/progress/mark-smoked'),
      headers: _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Falha ao registrar recaída (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
      );
    }
  }

  /// Registra um momento de vontade.
  /// outcome: 'overcome' (passou), 'smoked' (fumou) ou 'abandoned' (saiu).
  /// Retorna overcome_total e, se fumou, previous_clean_days.
  Future<Map<String, dynamic>> recordCraving({
    required String outcome,
    required DateTime startedAt,
    required int durationSeconds,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/progress/cravings'),
      headers: _headers(),
      body: jsonEncode({
        'outcome': outcome,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_seconds': durationSeconds,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Falha ao registrar vontade (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
      );
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}