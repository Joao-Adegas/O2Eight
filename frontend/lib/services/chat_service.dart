// lib/services/chat_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String? id;
  final String sender; // 'usuario' ou 'bot'
  final String content;
  final DateTime? sentAt;

  const ChatMessage({
    this.id,
    required this.sender,
    required this.content,
    this.sentAt,
  });

  bool get isUser => sender == 'usuario';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['uuid'] as String?,
      sender: (json['remetente'] as String?) ?? 'bot',
      content: (json['conteudo'] as String?) ?? '',
      sentAt: DateTime.tryParse((json['enviado_em'] as String?) ?? '')?.toLocal(),
    );
  }
}

class ChatSessionInfo {
  final String id;
  final String? title;
  final DateTime? createdAt;

  const ChatSessionInfo({required this.id, this.title, this.createdAt});

  factory ChatSessionInfo.fromJson(Map<String, dynamic> json) {
    return ChatSessionInfo(
      id: json['uuid'] as String,
      title: json['titulo'] as String?,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '')?.toLocal(),
    );
  }
}

class ChatService {
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

  dynamic _decode(http.Response res, String action) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode == 200) return jsonDecode(body);

    if (res.statusCode == 502) {
      throw Exception(
        'A assistente está indisponível agora. Tente de novo em instantes.',
      );
    }
    throw Exception('Falha ao $action (${res.statusCode}): $body');
  }

  Future<List<ChatSessionInfo>> listSessions() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/chat/sessions'),
      headers: _headers(),
    );
    final data = _decode(res, 'listar conversas') as List<dynamic>;
    return data
        .map((e) => ChatSessionInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatSessionInfo> createSession({String? title}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chat/sessions'),
      headers: _headers(),
      body: jsonEncode({'titulo': title}),
    );
    return ChatSessionInfo.fromJson(
      _decode(res, 'criar conversa') as Map<String, dynamic>,
    );
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/chat/sessions/$sessionId'),
      headers: _headers(),
    );
    final data = _decode(res, 'carregar conversa') as Map<String, dynamic>;
    return (data['mensagens'] as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retorna [mensagem do usuário, resposta do bot]
  Future<List<ChatMessage>> sendMessage(String sessionId, String content) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chat/sessions/$sessionId/messages'),
      headers: _headers(),
      body: jsonEncode({'conteudo': content}),
    );
    final data = _decode(res, 'enviar mensagem') as List<dynamic>;
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}