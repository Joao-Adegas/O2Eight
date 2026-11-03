// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lê o arquivo .env da raiz do frontend (declarado em assets no pubspec.yaml)
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Defina SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env do frontend.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Se a sessão salva expirou (app ficou fechado por mais de 1 hora),
  // renova antes de abrir as telas. Se não conseguir, volta para o login.
  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await auth.refreshSession();
    } catch (_) {
      await auth.signOut();
    }
  }

  runApp(const IntegradorApp());
}