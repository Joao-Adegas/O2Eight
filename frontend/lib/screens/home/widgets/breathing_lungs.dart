// lib/screens/home/widgets/breathing_lungs.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Recuperação estimada (0.0 a 1.0) a partir do tempo sem fumar.
/// Os pontos seguem os marcos divulgados pelo INCA (2h, 8h, 24h, 48h,
/// 3 semanas, 1 ano, 5 anos). É um indicador educativo, não um diagnóstico.
double estimateLungRecovery(Duration clean) {
  const points = <List<double>>[
    [0, 0.05], // acabou de fumar
    [2, 0.10], // nicotina deixa de circular no sangue
    [8, 0.15], // oxigênio no sangue se normaliza
    [24, 0.20], // pulmões funcionando melhor
    [48, 0.28], // olfato e paladar melhoram
    [504, 0.45], // 3 semanas: respiração mais fácil
    [2160, 0.65], // ~3 meses
    [8760, 0.85], // 1 ano: risco de infarto cai pela metade
    [43800, 1.00], // 5 anos
  ];

  final hours = clean.inMinutes / 60.0;
  if (hours <= 0) return points.first[1];

  for (var i = 1; i < points.length; i++) {
    final h0 = points[i - 1][0], v0 = points[i - 1][1];
    final h1 = points[i][0], v1 = points[i][1];
    if (hours <= h1) {
      final t = (hours - h0) / (h1 - h0);
      return v0 + (v1 - v0) * t;
    }
  }
  return 1.0;
}

/// Cor do estado: coral (recente) → âmbar → verde-água (saudável).
Color lungStatusColor(double recovery) {
  const stops = [
    Color(0xFFFF8A65),
    Color(0xFFFFC857),
    Color(0xFF7FE0CF),
    Color(0xFF3CCCB4),
  ];
  final scaled = recovery.clamp(0.0, 1.0) * (stops.length - 1);
  final i = math.min(scaled.floor(), stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], scaled - i)!;
}

String lungStatusLabel(double recovery) {
  if (recovery < 0.2) return 'Respiração irregular';
  if (recovery < 0.45) return 'Respiração se estabilizando';
  if (recovery < 0.75) return 'Respiração estável';
  return 'Respiração saudável';
}

/// Pulmão animado: a respiração fica mais lenta, profunda e regular
/// conforme a recuperação aumenta.
class BreathingLungs extends StatefulWidget {
  /// 0.0 = acabou de fumar, 1.0 = recuperação plena
  final double recovery;

  /// Diâmetro total do componente (anel incluso)
  final double size;

  const BreathingLungs({
    super.key,
    required this.recovery,
    this.size = 210,
  });

  @override
  State<BreathingLungs> createState() => _BreathingLungsState();
}

class _BreathingLungsState extends State<BreathingLungs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Duração de um ciclo: ~1,3 s (ofegante) até ~4,2 s (calma)
  Duration _periodFor(double r) =>
      Duration(milliseconds: (1300 + 2900 * r.clamp(0.0, 1.0)).round());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _periodFor(widget.recovery),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant BreathingLungs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPeriod = _periodFor(widget.recovery);
    final diff = (newPeriod - _controller.duration!).abs();
    if (diff > const Duration(milliseconds: 150)) {
      _controller.duration = newPeriod;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Posição da respiração no ciclo: 0 = expirado, 1 = inspirado.
  double _breath(double t, double r) {
    // Saudável: onda suave e simétrica
    final smooth = 0.5 - 0.5 * math.cos(2 * math.pi * t);

    // Ofegante: duas inspirações curtas e desiguais por ciclo
    final quick = 0.5 - 0.5 * math.cos(4 * math.pi * t);
    final labored = t < 0.5 ? quick : 0.55 * quick;

    // Quanto menor a recuperação, mais irregular
    final irregularity = (1 - r / 0.45).clamp(0.0, 1.0);
    final tremor = math.sin(2 * math.pi * t * 11) * 0.06 * irregularity;

    final value =
        smooth * (1 - irregularity) + labored * irregularity + tremor;
    return value.clamp(0.0, 1.0);
  }

  /// Matriz que tira a saturação (s = 1 cores normais, s = 0 cinza)
  List<double> _saturationMatrix(double s) {
    const rw = 0.2126, gw = 0.7152, bw = 0.0722;
    final inv = 1 - s;
    return <double>[
      rw * inv + s, gw * inv, bw * inv, 0, 0,
      rw * inv, gw * inv + s, bw * inv, 0, 0,
      rw * inv, gw * inv, bw * inv + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recovery.clamp(0.0, 1.0);
    final color = lungStatusColor(r);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final amplitude = 0.03 + 0.05 * r; // expansão: 3% (curta) a 8% (profunda)
    final saturation = 0.35 + 0.65 * r; // pulmão mais cinza no início
    final discSize = widget.size * 0.74;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anel de recuperação (anima ao carregar e quando a % muda)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: r),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _RingPainter(progress: value, color: color),
            ),
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final b = reduceMotion ? 0.5 : _breath(_controller.value, r);
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Disco branco com brilho que acompanha a respiração
                  Container(
                    width: discSize,
                    height: discSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.18 + 0.32 * b),
                          blurRadius: 24 + 30 * b,
                          spreadRadius: 2 + 8 * b,
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(scale: 1 + amplitude * b, child: child),
                ],
              );
            },
            child: SizedBox(
              width: discSize * 0.68,
              height: discSize * 0.68,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
                child: Image.asset('images/logo.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}