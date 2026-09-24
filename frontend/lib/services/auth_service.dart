import 'dart:convert';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Trocar pela URL real em produção. Para emulador Android use 10.0.2.2.
  static const String _baseUrl = 'http://localhost:8000';

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.o2eight://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Sincroniza o usuário logado com o backend e retorna os dados
  /// já mesclados (id, email, phone, name, created_at).
  Future<Map<String, dynamic>> registerSsoAndFetchUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Nenhuma sessão ativa encontrada');
    }

    final token = session.accessToken;

    final registerResponse = await http.post(
      Uri.parse('$_baseUrl/auth/register-sso'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (registerResponse.statusCode != 200) {
      throw Exception('Falha ao registrar usuário: ${registerResponse.body}');
    }

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

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}