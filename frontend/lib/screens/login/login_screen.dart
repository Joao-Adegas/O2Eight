// lib/screens/login/login_screen.dart
import 'dart:async';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<AuthState>? _authSub;
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool _obscurePassword = true;
  bool _navigated = false; // evita navegar para a Home duas vezes

  // Cores (cores explícitas em tudo: o app abre em tema escuro por padrão)
  static const _navy = Color(0xFF143B74);
  static const _textDark = Color(0xFF1A2A3A);
  static const _textMuted = Color(0xFF6B7785);
  static const _border = Color(0xFFDDE3EA);

  bool get _isBusy => _isGoogleLoading || _isEmailLoading;

  // ───────────────────────── Lógica ─────────────────────────

  @override
  void initState() {
    super.initState();

    // Já existe sessão salva (ex: voltou do redirect do Google no Web)
    if (_authService.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }

    // Login concluído enquanto esta tela está aberta
    _authSub = _authService.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) _goHome();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// A Home chama o register-sso sozinha, então aqui só navegamos.
  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  Future<void> _onEmailPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Preencha o e-mail e a senha.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isEmailLoading = true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _goHome();
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _onGooglePressed() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      // No Web a página sai para o Google e volta recarregada;
      // o initState acima detecta a sessão e vai para a Home.
    } catch (e) {
      if (!mounted) return;
      _showMessage('Não foi possível entrar com o Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _comingSoon(String feature) {
    _showMessage('$feature ainda não está disponível.');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho ocupa a largura total da tela
            _buildHeader(),

            // Só o formulário fica limitado a 420px e centralizado
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _buildForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 250,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3CCCB4), Color(0xFF1A7FA8), _navy],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset('images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 14),
              const Text(
                'O₂Eight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28), // espaço para a onda
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Bem-vindo de volta',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Entre na sua conta para continuar',
          style: TextStyle(fontSize: 14, color: _textMuted),
        ),
        const SizedBox(height: 24),

        // ── E-mail ──
        _label('E-mail'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          style: const TextStyle(color: _textDark),
          cursorColor: _navy,
          decoration: _inputDecoration(
            hint: 'seu@email.com',
            icon: Icons.mail_outline,
          ),
        ),
        const SizedBox(height: 16),

        // ── Senha ──
        _label('Senha'),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) {
            if (!_isBusy) _onEmailPressed();
          },
          style: const TextStyle(color: _textDark),
          cursorColor: _navy,
          decoration: _inputDecoration(
            hint: 'Digite sua senha',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _comingSoon('Recuperação de senha'),
            style: TextButton.styleFrom(foregroundColor: _navy),
            child: const Text(
              'Esqueceu sua senha?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Botão Entrar ──
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isBusy ? null : _onEmailPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              disabledBackgroundColor: _navy.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: _navy.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isEmailLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Divisor ──
        const Row(
          children: [
            Expanded(child: Divider(color: _border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou continue com',
                style: TextStyle(fontSize: 13, color: _textMuted),
              ),
            ),
            Expanded(child: Divider(color: _border)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Botões sociais ──
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Apple',
                icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                onPressed: () => _comingSoon('Login com Apple'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: Image.asset(
                  'images/google_logo.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                loading: _isGoogleLoading,
                onPressed: _isBusy ? null : _onGooglePressed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // ── Rodapé ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Não tem conta? ',
              style: TextStyle(fontSize: 14, color: _textMuted),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.signup),
              child: const Text(
                'Cadastre-se',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted),
      prefixIcon: Icon(icon, color: _textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
    );
  }
}

/// Botão branco com borda (Apple / Google)
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool loading;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDDE3EA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Recorta a parte de baixo do cabeçalho em formato de onda
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..lineTo(0, h - 20)
      ..quadraticBezierTo(w * 0.25, h - 45, w * 0.5, h - 25)
      ..quadraticBezierTo(w * 0.75, h - 5, w, h - 40)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}