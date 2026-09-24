import 'package:flutter/material.dart';
import 'package:flutter_version/models/trigger_data.dart';

import 'trigger_card.dart';

class TriggerCarousel extends StatefulWidget {
  final List<TriggerData> triggers;
  final double cardWidth;
  final double cardHeight;

  const TriggerCarousel({
    super.key,
    required this.triggers,
    this.cardWidth = 150,
    this.cardHeight = 190,
  });

  @override
  State<TriggerCarousel> createState() => _TriggerCarouselState();
}

class _TriggerCarouselState extends State<TriggerCarousel> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: widget.triggers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final trigger = widget.triggers[index];
          return TriggerCard(
            data: trigger,
            width: widget.cardWidth,
            isSelected: index == _selectedIndex,
            onTap: () => setState(() => _selectedIndex = index),
          );
        },
      ),
    );
  }
}