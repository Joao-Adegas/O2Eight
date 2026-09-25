import 'package:flutter/material.dart';
import 'package:flutter_version/app/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Se já existe sessão ativa ao abrir o app, pula direto pra Home
    final existingSession = _authService.currentSession;
    if (existingSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      });
    }

    _authService.authStateChanges.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        await _handleLoginSuccess();
      }
    });
  }

  Future<void> _handleLoginSuccess() async {
    setState(() => _isLoading = true);
    try {
      await _authService.registerSsoAndFetchUser();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onGooglePressed() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // Não precisa navegar aqui: o listener acima detecta o signIn
      // automaticamente e chama _handleLoginSuccess.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar login: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _onGooglePressed,
                icon: const Icon(Icons.login),
                label: const Text('Entrar com Google'),
              ),
      ),
    );
  }
}