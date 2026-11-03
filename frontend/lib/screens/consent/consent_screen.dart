// lib/screens/consent/consent_screen.dart
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

/// Termo de consentimento, exibido depois do login e antes do formulário.
/// Aparece de novo sempre que [termsVersion] mudar.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  /// Precisa ser igual a CURRENT_TERMS_VERSION no backend (api/v1/routes/auth.py).
  static const termsVersion = '1.0';

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _TermSection {
  final IconData icon;
  final String title;
  final String body;

  const _TermSection(this.icon, this.title, this.body);
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _authService = AuthService();

  bool _accepted = false;
  bool _isSaving = false;

  // RASCUNHO: validar este texto com o orientador antes de publicar o app.
  static const _contactEmail = '[E-MAIL DE CONTATO DA EQUIPE]';

  static const _sections = [
    _TermSection(
      Icons.description_outlined,
      'Quais dados coletamos',
      'Seu nome e e-mail; as respostas do formulário inicial, como há quanto '
          'tempo fuma, quantos cigarros por dia, gatilhos, motivações e '
          'histórico de saúde da família; seu progresso e os momentos de '
          'vontade que você registra; o uso do dispositivo O₂Eight; suas '
          'conversas com a assistente; e o que você publica na comunidade.',
    ),
    _TermSection(
      Icons.health_and_safety_outlined,
      'Dados de saúde',
      'Informações sobre o hábito de fumar e o histórico de doenças na '
          'família são dados pessoais sensíveis pela Lei Geral de Proteção de '
          'Dados (LGPD). Só os tratamos com o seu consentimento, dado nesta tela.',
    ),
    _TermSection(
      Icons.track_changes_outlined,
      'Para que usamos',
      'Para calcular seu progresso e o dinheiro economizado, mostrar os marcos '
          'de recuperação, identificar seus momentos de maior risco e '
          'personalizar as respostas da assistente.',
    ),
    _TermSection(
      Icons.smart_toy_outlined,
      'Assistente de inteligência artificial',
      'Para responder, a assistente envia suas mensagens e um resumo do seu '
          'perfil (dias sem fumar, gatilhos e motivações) a um serviço externo '
          'de inteligência artificial (Groq), que pode processar os dados fora '
          'do Brasil. A assistente não substitui um profissional de saúde.',
    ),
    _TermSection(
      Icons.groups_outlined,
      'Comunidade',
      'O que você publica fica visível para os outros usuários. Você pode '
          'publicar e comentar como anônimo: seu nome não aparece, mas seus '
          'dias sem fumar sim.',
    ),
    _TermSection(
      Icons.lock_outline,
      'Como protegemos',
      'Seus dados ficam armazenados com criptografia, e só você acessa as suas '
          'informações pessoais pelo app. Não vendemos nem compartilhamos dados '
          'que identifiquem você. Em pesquisas, os dados só serão usados de '
          'forma agregada e anônima.',
    ),
    _TermSection(
      Icons.verified_user_outlined,
      'Seus direitos',
      'Você pode pedir acesso, correção ou exclusão dos seus dados e retirar '
          'este consentimento a qualquer momento, pelo e-mail $_contactEmail. '
          'Sem o consentimento, não é possível usar o app.',
    ),
  ];

  // ───────────────────────── Lógica ─────────────────────────

  Future<void> _accept() async {
    if (!_accepted || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await _authService.acceptConsent(ConsentScreen.termsVersion);
      if (!mounted) return;
      // A Home volta a carregar e segue para o formulário, se for o primeiro acesso
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      debugPrint('ERRO ao registrar consentimento: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível registrar seu aceite. Tente de novo.'),
        ),
      );
    }
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair sem aceitar?'),
        content: const Text(
          'Sem o seu consentimento não é possível usar o O₂Eight. '
          'Você vai sair da conta e pode voltar quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar ao termo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.navy50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: AppColors.navy700, size: 28),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Antes de começar',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Para acompanhar sua jornada, o O₂Eight precisa '
                          'guardar algumas informações sobre você e sua saúde. '
                          'Leia como elas são usadas.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.large,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < _sections.length; i++) ...[
                                if (i > 0) const Divider(indent: 60),
                                _SectionTile(section: _sections[i]),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Termo de consentimento, versão ${ConsentScreen.termsVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: _isSaving
                    ? null
                    : () => setState(() => _accepted = !_accepted),
                borderRadius: AppRadius.medium,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: _isSaving
                            ? null
                            : (v) => setState(() => _accepted = v ?? false),
                        activeColor: AppColors.navy700,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Li e concordo com o termo, e autorizo o tratamento '
                            'dos meus dados, incluindo dados de saúde, para as '
                            'finalidades descritas.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _accepted && !_isSaving ? _accept : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Aceitar e continuar'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: _isSaving ? null : _decline,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Não aceito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final _TermSection section;

  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.navy50,
              shape: BoxShape.circle,
            ),
            child: Icon(section.icon, size: 17, color: AppColors.navy700),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  section.body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}