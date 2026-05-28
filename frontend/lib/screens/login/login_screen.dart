import 'package:flutter/material.dart';

import '../../components/gradient_button.dart';
import '../../core/theme/app_theme.dart';
import '../../app/routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color.fromARGB(255, 255, 255, 255), // Cor sólida
          ),

          // Logo
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  width: double.infinity,
                  height: 520,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3CCCB4), Color(0xFF0F5A8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 70),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Image.asset('assets/images/logo.png'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.apple,size: 32,),
                label: Text('Entrar com Apple'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(450, 50),
                    backgroundColor:
                        const Color.fromARGB(255, 0, 0, 0), // cor de fundo
                    foregroundColor: Colors.white, // cor do texto e ícone
                    padding: EdgeInsets.all(20)),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.facebook,size: 32,),
                label: Text('Entrar com Apple'),
                style: ElevatedButton.styleFrom(
                   minimumSize: Size(450, 50),
                    backgroundColor:
                        const Color.fromARGB(255, 58, 127, 238),
                    foregroundColor: Colors.white, // cor do texto e ícone
                    padding: EdgeInsets.all(20)),
              )
              //inputs
              // login button
            ],
          )
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.7);

    // Cria a curva da onda
    var firstControlPoint = Offset(size.width / 4, size.height * 0.8);
    var firstEndPoint = Offset(size.width / 2, size.height * 0.75);

    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.7);
    var secondEndPoint = Offset(size.width, size.height * 0.8);

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

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
