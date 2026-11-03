// lib/screens/home/widgets/progress_hero.dart
import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_version/services/auth_service.dart';
import 'package:flutter_version/widgets/user_avatar_menu.dart';

import 'breathing_lungs.dart';

/// Topo da Home: saudação, pulmão animado, dias sem fumar em destaque
/// e dinheiro economizado subindo em tempo real.
class ProgressHero extends StatefulWidget {
  final String userName;
  final AuthService authService;
  final DateTime cleanSince;
  final double dailyCost;

  const ProgressHero({
    super.key,
    required this.userName,
    required this.authService,
    required this.cleanSince,
    required this.dailyCost,
  });

  @override
  State<ProgressHero> createState() => _ProgressHeroState();
}

class _ProgressHeroState extends State<ProgressHero> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  void initState() {
    super.initState();
    // Atualiza a cada segundo: o dinheiro economizado sobe em tempo real
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ───────────────────────── Cálculos ─────────────────────────

  Duration get _clean {
    final d = _now.difference(widget.cleanSince);
    return d.isNegative ? Duration.zero : d;
  }

  double get _savedMoney => _clean.inSeconds / 86400 * widget.dailyCost;

  bool get _showDays => _clean.inDays >= 1;

  String get _timeValue {
    final c = _clean;
    if (c.inDays >= 1) return '${c.inDays}';
    if (c.inHours >= 1) return '${c.inHours}h ${c.inMinutes % 60}min';
    return '${c.inMinutes}min';
  }

  String get _timeLabel {
    if (!_showDays) return 'sem fumar';
    return _clean.inDays == 1 ? 'dia sem fumar' : 'dias sem fumar';
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _firstName {
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'você' : parts.first;
  }

  static String _formatMoney(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integer,${parts[1]}';
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ───────────────────────── Visual ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final recovery = estimateLungRecovery(_clean);
    final statusColor = lungStatusColor(recovery);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D4F7C), Color(0xFF0B2A4A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  BreathingLungs(recovery: recovery, size: 210),
                  const SizedBox(height: 16),
                  _buildStatusPill(recovery, statusColor),
                  const SizedBox(height: 24),
                  _buildMainNumber(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.savings_outlined,
                          label: 'Economizado',
                          value: _formatMoney(_savedMoney),
                          accent: statusColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.event_available_outlined,
                          label: 'Sem fumar desde',
                          value: _formatDate(widget.cleanSince),
                          accent: statusColor,
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
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $_firstName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Veja como seu corpo está hoje',
                style: TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ),
        UserAvatarMenu(
          userName: widget.userName,
          authService: widget.authService,
        ),
      ],
    );
  }

  Widget _buildStatusPill(double recovery, Color color) {
    final percent = (recovery * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${lungStatusLabel(recovery)} · $percent% recuperado',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFeatures: _tabular,
            ),
          ),
          const SizedBox(width: 6),
          const Tooltip(
            message:
                'Estimativa educativa baseada nos marcos de recuperação '
                'divulgados pelo INCA. Não é um diagnóstico médico.',
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(Icons.info_outline, size: 15, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildMainNumber() {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _timeValue,
            style: TextStyle(
              fontSize: _showDays ? 84 : 56,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
              letterSpacing: -2,
              fontFeatures: _tabular,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _timeLabel,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}