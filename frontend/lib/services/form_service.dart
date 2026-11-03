// lib/services/form_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/core/config/app_config.dart';

class FormService {
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

  /// Formulário do usuário, ou null se ainda não foi preenchido (primeiro acesso).
  Future<Map<String, dynamic>?> getMyForm() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/form/me'),
      headers: _headers(),
    );
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception(
        'Falha ao buscar formulário (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
      );
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// true = usuário já respondeu o formulário; false = primeiro acesso.
  Future<bool> hasForm() async => (await getMyForm()) != null;

  /// Envia (ou atualiza) as respostas do formulário.
  Future<Map<String, dynamic>> submitForm(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/form/submit'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Falha ao salvar formulário (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
      );
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}