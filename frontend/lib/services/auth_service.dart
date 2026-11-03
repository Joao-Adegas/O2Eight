// lib/services/auth_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/core/config/app_config.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static String get _baseUrl => AppConfig.apiBaseUrl;

  // ───────────────────────── Login ─────────────────────────

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? 'http://localhost:5000'
          : 'io.supabase.o2eight://login-callback',
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name}, // o backend usa isso como nome em /auth/register-sso
      emailRedirectTo:
          kIsWeb ? 'http://localhost:5000' : 'io.supabase.o2eight://login-callback',
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Traduz os erros do Supabase Auth para mensagens em português.
  static String friendlyError(Object error) {
    if (error is AuthException) {
      switch (error.code) {
        case 'invalid_credentials':
          return 'E-mail ou senha incorretos.';
        case 'email_not_confirmed':
          return 'Confirme seu e-mail antes de entrar. Veja sua caixa de entrada.';
        case 'user_already_exists':
        case 'email_exists':
          return 'Já existe uma conta com esse e-mail.';
        case 'weak_password':
          return 'Senha fraca. Use pelo menos 6 caracteres.';
        case 'over_email_send_rate_limit':
        case 'over_request_rate_limit':
          return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
        case 'validation_failed':
          return 'Verifique o e-mail informado.';
      }
      return error.message;
    }
    return 'Algo deu errado: $error';
  }

  // ───────────────────────── Backend ─────────────────────────

  String _requireToken() {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }
    return session.accessToken;
  }

  /// Cria o usuário em public.users (se ainda não existir) e devolve os dados.
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

  /// Só lê os dados do usuário já registrado.
  Future<Map<String, dynamic>> fetchCurrentUser() async {
    final token = _requireToken();

    final meResponse = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (meResponse.statusCode != 200) {
      throw Exception('Falha ao buscar usuário: ${meResponse.body}');
    }

    return jsonDecode(utf8.decode(meResponse.bodyBytes)) as Map<String, dynamic>;
  }

  /// Registra o aceite do termo de consentimento na versão informada.
  Future<Map<String, dynamic>> acceptConsent(String version) async {
    final token = _requireToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/consent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'version': version}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao registrar consentimento: ${utf8.decode(response.bodyBytes)}',
      );
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // ───────────────────────── Getters ─────────────────────────

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  /// Foto do perfil do Google (o Supabase salva no user_metadata)
  String? get avatarUrl {
    final meta = _supabase.auth.currentUser?.userMetadata;
    return (meta?['avatar_url'] ?? meta?['picture']) as String?;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}