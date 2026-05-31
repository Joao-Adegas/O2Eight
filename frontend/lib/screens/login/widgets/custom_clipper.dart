import 'package:flutter/rendering.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.72);
    var firstControlPoint = Offset(size.width / 4, size.height * 0.82);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.76);
    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.70);
    var secondEndPoint = Offset(size.width, size.height * 0.80);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}