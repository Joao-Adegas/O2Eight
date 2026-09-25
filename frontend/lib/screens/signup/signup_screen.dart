// lib/screens/signup/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_version/app/routes.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _navy = Color(0xFF143B74);
  static const _textDark = Color(0xFF1A2A3A);
  static const _textMuted = Color(0xFF6B7785);
  static const _border = Color(0xFFDDE3EA);
  static const _error = Color(0xFFC62828);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ───────────────────────── Lógica ─────────────────────────

  Future<void> _onSignUpPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final res = await _authService.signUpWithEmail(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );
      if (!mounted) return;

      // Com "Confirm email" ligado, o Supabase não dá erro para e-mail
      // repetido: devolve um usuário sem identidades. Tratamos aqui.
      final identities = res.user?.identities;
      if (identities != null && identities.isEmpty) {
        _showMessage('Já existe uma conta com esse e-mail. Tente entrar.');
        return;
      }

      // "Confirm email" desligado → já vem logado
      if (res.session != null) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        return;
      }

      // "Confirm email" ligado → precisa clicar no link do e-mail
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirme seu e-mail'),
          content: Text(
            'Enviamos um link de confirmação para $email. '
            'Abra o link e depois entre com seu e-mail e senha.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(); // volta para o login
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ───────────────────────── Validações ─────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) return 'Informe seu nome';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Informe um e-mail válido';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'As senhas não conferem';
    return null;
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Voltar',
                          icon: const Icon(Icons.arrow_back, color: _navy),
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preencha seus dados para começar',
                        style: TextStyle(fontSize: 14, color: _textMuted),
                      ),
                      const SizedBox(height: 24),

                      _label('Nome'),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        validator: _validateName,
                        style: const TextStyle(color: _textDark),
                        cursorColor: _navy,
                        decoration: _inputDecoration(
                          hint: 'Como você quer ser chamado',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('E-mail'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: _validateEmail,
                        style: const TextStyle(color: _textDark),
                        cursorColor: _navy,
                        decoration: _inputDecoration(
                          hint: 'seu@email.com',
                          icon: Icons.mail_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Senha'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validatePassword,
                        style: const TextStyle(color: _textDark),
                        cursorColor: _navy,
                        decoration: _inputDecoration(
                          hint: 'Mínimo de 6 caracteres',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Confirmar senha'),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: _validateConfirm,
                        onFieldSubmitted: (_) {
                          if (!_isLoading) _onSignUpPressed();
                        },
                        style: const TextStyle(color: _textDark),
                        cursorColor: _navy,
                        decoration: _inputDecoration(
                          hint: 'Digite a senha novamente',
                          icon: Icons.lock_outline,
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSignUpPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            disabledBackgroundColor:
                                _navy.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: _navy.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Criar conta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tem conta? ',
                            style: TextStyle(fontSize: 14, color: _textMuted),
                          ),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text(
                              'Entrar',
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted),
      errorStyle: const TextStyle(color: _error),
      prefixIcon: Icon(icon, color: _textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: border(_border),
      focusedBorder: border(_navy, 1.5),
      errorBorder: border(_error),
      focusedErrorBorder: border(_error, 1.5),
    );
  }
}