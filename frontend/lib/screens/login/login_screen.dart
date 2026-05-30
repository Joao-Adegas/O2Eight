import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // HEADER
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  width: double.infinity,

                  // cresce conforme largura da tela
                  height: (size.width * 0.75).clamp(320, 650),

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF3CCCB4),
                        Color(0xFF0F5A8F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),

                  child: Align(
                    alignment: Alignment.center,

                    child: Transform.translate(
                      offset: const Offset(0, -40),

                      child: Container(
                        width: size.width * 0.28,
                        height: size.width * 0.28,

                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),

                        alignment: Alignment.center,

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // FORM
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Column(
                      children: [

                        // APPLE
                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(
                            onPressed: () {},

                            icon: const Icon(
                              Icons.apple,
                              size: 28,
                            ),

                            label: const Text(
                              'Entrar com Apple',
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // FACEBOOK
                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton.icon(
                            onPressed: () {},

                            icon: const Icon(
                              Icons.facebook,
                              size: 28,
                            ),

                            label: const Text(
                              'Entrar com Facebook',
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF3A7FEE),

                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // EMAIL
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Email',

                            prefixIcon: const Icon(
                              Icons.email,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SENHA
                        TextField(
                          obscureText: true,

                          decoration: InputDecoration(
                            labelText: 'Senha',

                            prefixIcon: const Icon(
                              Icons.lock,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // LOGIN
                        SizedBox(
                          width: double.infinity,

                          child: ElevatedButton(
                            onPressed: () {},

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF143A74),

                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),

                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0, size.height * 0.72);

    var firstControlPoint =
        Offset(size.width / 4, size.height * 0.82);

    var firstEndPoint =
        Offset(size.width / 2, size.height * 0.76);

    var secondControlPoint =
        Offset(size.width * 0.75, size.height * 0.70);

    var secondEndPoint =
        Offset(size.width, size.height * 0.80);

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