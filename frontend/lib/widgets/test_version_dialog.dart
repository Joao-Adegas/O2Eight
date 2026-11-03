// lib/widgets/test_version_dialog.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

/// Aviso de versão de teste: o app ainda não está na Google Play nem na
/// App Store e é distribuído por APK. Aparece uma vez por usuário neste
/// aparelho; se o texto mudar, aumente [_noticeVersion] para mostrar de novo.
const _noticeVersion = '1';

String _prefsKey(String userId) => 'test_version_notice_v${_noticeVersion}_$userId';

/// Mostra o aviso se o usuário ainda não confirmou neste aparelho.
/// Retorna true se pode continuar (já tinha confirmado ou confirmou agora)
/// e false se escolheu sair.
Future<bool> showTestVersionNoticeIfNeeded(
  BuildContext context, {
  required String userId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_prefsKey(userId)) == true) return true;
  if (!context.mounted) return true;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _TestVersionDialog(),
  );

  if (accepted == true) {
    await prefs.setBool(_prefsKey(userId), true);
    return true;
  }
  return false;
}

class _NoticeItem {
  final IconData icon;
  final String title;
  final String body;

  const _NoticeItem(this.icon, this.title, this.body);
}

class _TestVersionDialog extends StatefulWidget {
  const _TestVersionDialog();

  @override
  State<_TestVersionDialog> createState() => _TestVersionDialogState();
}

class _TestVersionDialogState extends State<_TestVersionDialog> {
  bool _checked = false;

  static const _items = [
    _NoticeItem(
      Icons.storefront_outlined,
      'Fora das lojas oficiais',
      'O O₂Eight ainda não está publicado na Google Play nem na App Store. '
          'Você o instalou por um arquivo APK, fora das lojas.',
    ),
    _NoticeItem(
      Icons.gpp_maybe_outlined,
      'Sem a revisão de segurança das lojas',
      'Por isso, o app não passou pelas análises de segurança, privacidade '
          'e qualidade que a Google e a Apple fazem antes de publicar um '
          'aplicativo. Só instale o APK recebido diretamente da equipe do projeto.',
    ),
    _NoticeItem(
      Icons.science_outlined,
      'Versão de testes',
      'Esta é uma versão de um projeto acadêmico, usada para testes. Podem '
          'ocorrer erros, lentidão (a primeira abertura do dia pode levar até '
          'um minuto) e mudanças nas funções e nos dados.',
    ),
    _NoticeItem(
      Icons.health_and_safety_outlined,
      'Não substitui acompanhamento profissional',
      'O app é um apoio para parar de fumar. Para tratamento, procure um '
          'profissional de saúde ou o SUS.',
    ),
  ];

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do app?'),
        content: const Text(
          'Para usar a versão de testes, é preciso confirmar o aviso. '
          'Você vai sair da conta e pode voltar quando quiser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar ao aviso'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return PopScope(
      // O botão voltar do Android não fecha o aviso
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.statusStabilizing.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.science_outlined,
                            color: AppColors.navy900, size: 26),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Versão de testes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Antes de continuar, leia este aviso sobre como o app '
                        'está sendo distribuído.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (final item in _items) _NoticeTile(item: item),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _checked = !_checked),
                      borderRadius: AppRadius.medium,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _checked,
                              onChanged: (v) => setState(() => _checked = v ?? false),
                              activeColor: AppColors.navy700,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  'Entendi que o app é uma versão de testes, '
                                  'instalada por APK e sem a revisão de segurança '
                                  'da Google Play e da App Store, e quero continuar.',
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
                      onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
                      child: const Text('Continuar'),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: _confirmExit,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final _NoticeItem item;

  const _NoticeTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
            child: Icon(item.icon, size: 17, color: AppColors.navy700),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
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
