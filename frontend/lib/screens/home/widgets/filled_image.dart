import 'package:flutter/material.dart';

class FilledImage extends StatelessWidget {
  final String imagePath;
  final double fillPercent; // 0.0 a 1.0
  final Color filledColor;

  const FilledImage({
    super.key,
    this.imagePath = "images/logo.png",
    required this.fillPercent,
    this.filledColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camada cinza (fundo)
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ]),
          child: Image.asset(imagePath,width: 150,height: 150,),
        ),

        // Camada colorida com máscara de corte
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              stops: [fillPercent, fillPercent],
              colors: const [Colors.white, Colors.transparent],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Image.asset(imagePath,width: 150,height: 150),
        ),
      ],
    );
  }
}