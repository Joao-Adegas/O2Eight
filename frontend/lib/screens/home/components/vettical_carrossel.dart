import 'package:flutter/material.dart';

class VerticalCarousel extends StatefulWidget {
  final List<String> items;
  final double itemHeight;

  const VerticalCarousel({
    super.key,
    required this.items,
    this.itemHeight = 70,
  });

  @override
  State<VerticalCarousel> createState() => _VerticalCarouselState();
}

class _VerticalCarouselState extends State<VerticalCarousel> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.42, // controla quanto dos itens vizinhos aparece
      initialPage: 0,
    );
    _controller.addListener(() {
      setState(() {
        _page = _controller.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight * 3, // altura visível do carrossel
      child: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final distance = (index - _page).abs();
          // quanto mais perto do centro, maior escala e opacidade
          final scale = (1 - (distance * 0.25)).clamp(0.8, 1.0);
          final opacity = (1 - (distance * 0.6)).clamp(0.3, 1.0);
          final isCenter = distance < 0.5;

          return Center(
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isCenter ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isCenter
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    widget.items[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCenter ? 15 : 13,
                      fontWeight: isCenter ? FontWeight.w600 : FontWeight.w400,
                      color: isCenter
                          ? const Color(0xFF0D4F7C)
                          : const Color(0xFF0D4F7C).withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}