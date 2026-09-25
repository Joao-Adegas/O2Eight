import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _teal = Color(0xFF3ABFBF);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? _teal.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? _teal : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? _teal : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

