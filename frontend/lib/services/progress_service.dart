// lib/services/progress_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  static const String _baseUrl = 'http://localhost:8000';

  Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }
    return {'Authorization': 'Bearer ${session.accessToken}'};
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
}