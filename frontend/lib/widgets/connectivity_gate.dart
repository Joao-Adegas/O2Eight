// lib/widgets/connectivity_gate.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Fica em volta de todas as telas do app (MaterialApp.builder).
/// Quando o aparelho está sem Wi-Fi e sem dados móveis, cobre a tela atual
/// com o aviso "Você está sem internet". Quando a conexão volta, o aviso
/// some sozinho e a pessoa continua de onde estava.
class ConnectivityGate extends StatefulWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _offline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
    _subscription = _connectivity.onConnectivityChanged.listen(_apply);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Sem conexão = nenhuma rede ativa (nem Wi-Fi, nem dados móveis, nem cabo).
  void _apply(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (e) {
      // Se não for possível consultar o estado da rede, não bloqueia o app
      debugPrint('Falha ao verificar conexão: $e');
    }
    // Pequena pausa para o botão mostrar que está verificando
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: _OfflineScreen(checking: _checking, onRetry: _check),
          ),
      ],
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  final bool checking;
  final VoidCallback onRetry;

  const _OfflineScreen({required this.checking, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.navy50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 44,
                      color: AppColors.navy700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Você está sem internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'O Wi-Fi e os dados móveis estão desligados ou sem sinal. '
                    'O O₂Eight precisa de conexão para mostrar seu progresso e '
                    'guardar seus registros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.large,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        _Tip(
                          icon: Icons.wifi_rounded,
                          text: 'Ligue o Wi-Fi e conecte-se a uma rede',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _Tip(
                          icon: Icons.signal_cellular_alt_rounded,
                          text: 'Ou ative os dados móveis',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _Tip(
                          icon: Icons.airplanemode_inactive_rounded,
                          text: 'Confira se o modo avião está desligado',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: checking ? null : onRetry,
                      child: checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Tentar de novo'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Esta tela some sozinha quando a conexão voltar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SosHint(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.teal700),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

/// Mesmo offline, a pessoa pode estar com vontade de fumar: deixa uma
/// orientação simples que não depende de internet.
class _SosHint extends StatelessWidget {
  const _SosHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.teal50,
        borderRadius: AppRadius.medium,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.air, size: 20, color: AppColors.teal700),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Com vontade de fumar agora? Respire fundo: inspire em 4 segundos, '
              'segure 4 e solte em 6. Repita algumas vezes. A vontade passa em '
              'poucos minutos.',
              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
