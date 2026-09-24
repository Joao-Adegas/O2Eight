import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://SEU_PROJETO.supabase.co', // mesmo SUPABASE_URL do backend
    anonKey: 'SUA_ANON_KEY',                 // mesma SUPABASE_KEY do backend
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O2Eight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // ajuste conforme sua fonte
      ),
      home: const AuthGate(),
    );
  }
}