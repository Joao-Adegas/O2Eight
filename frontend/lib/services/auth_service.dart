import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl = 'http://localhost:8000';

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? 'http://localhost:5000' // veja como descobrir a porta abaixo
          : 'io.supabase.o2eight://login-callback',
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  String _requireToken() {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }
    return session.accessToken;
  }

  /// Chamar só uma vez, logo após o login bem-sucedido.
  Future<Map<String, dynamic>> registerSsoAndFetchUser() async {
    final token = _requireToken();

    final registerResponse = await http.post(
      Uri.parse('$_baseUrl/auth/register-sso'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (registerResponse.statusCode != 200) {
      throw Exception('Falha ao registrar usuário: ${registerResponse.body}');
    }

    return fetchCurrentUser();
  }

  /// Chamar sempre que precisar só ler os dados do usuário já sincronizado
  /// (ex: toda vez que a HomeScreen constrói).
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final token = _requireToken();

    final meResponse = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (meResponse.statusCode != 200) {
      throw Exception('Falha ao buscar usuário: ${meResponse.body}');
    }

    return jsonDecode(meResponse.body) as Map<String, dynamic>;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  String? get avatarUrl {
    final meta = _supabase.auth.currentUser?.userMetadata;
    return (meta?['avatar_url'] ?? meta?['picture']) as String?;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
