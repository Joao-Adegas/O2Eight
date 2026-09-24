import 'package:flutter/material.dart';
import 'package:flutter_version/models/trigger_data.dart';


class TriggerCard extends StatelessWidget {
  final TriggerData data;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;

  const TriggerCard({
    super.key,
    required this.data,
    this.isSelected = false,
    this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFBFE0EE), // azul claro do mock
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A7FA8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Ícone de fundo, grande e translúcido
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                data.icon,
                size: 90,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            // Conteúdo (texto + barra)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D4F7C),
                  ),
                ),
                const SizedBox(height: 10),
                // Barra de progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.percentage,
                    minHeight: 4,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D4F7C),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // espaço para o ícone de fundo
              ],
            ),
          ],
        ),
      ),
    );
  }
}