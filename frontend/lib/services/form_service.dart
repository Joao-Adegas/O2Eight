// lib/services/form_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FormService {
  static const String _baseUrl = 'http://localhost:8000';

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

  /// true = usuário já respondeu o formulário; false = primeiro acesso.
  Future<bool> hasForm() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/form/me'),
      headers: _headers(),
    );
    if (res.statusCode == 200) return true;
    if (res.statusCode == 404) return false;
    throw Exception(
      'Falha ao verificar formulário (${res.statusCode}): ${utf8.decode(res.bodyBytes)}',
    );
  }

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