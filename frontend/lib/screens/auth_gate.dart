import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'login/login_screen.dart';
import 'home/home_screen.dart';

/// Decide qual tela mostrar com base no estado de autenticação.
/// Fica ouvindo mudanças de sessão o tempo todo (login, logout, refresh).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Se o app abrir já com sessão salva (usuário logou antes), sincroniza direto.
    final existingSession = _authService.currentSession;
    if (existingSession != null) {
      _syncUser();
    }

    // Escuta qualquer mudança de sessão durante a vida do app:
    // login novo (via deep link), logout, refresh de token expirado, etc.
    _authService.authStateChanges.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        _syncUser();
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _userData = null;
          _error = null;
        });
      }
    });
  }

  Future<void> _syncUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.registerSsoAndFetchUser();
      if (!mounted) return;
      setState(() {
        _userData = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao sincronizar usuário: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                    setState(() {
                      _userData = null;
                      _error = null;
                    });
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sessão ativa e usuário sincronizado -> Home
    if (_userData != null) {
      return HomeScreen(
        userName: _userData!['name'] ?? 'Usuário',
        onToggleTheme: () {}, // ajuste conforme sua lógica de tema
      );
    }

    // Sem sessão -> Login
    return const LoginScreen();
  }
}