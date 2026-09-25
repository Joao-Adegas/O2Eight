import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_version/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://difhqwxwkugrwfeeqexr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpZmhxd3h3a3VncndmZWVxZXhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNDIxNDIsImV4cCI6MjA5NDkxODE0Mn0.bb8CEu1cxDEbtel711vSsUBl7DRaTb9Y6ZFLt3bdi_k',
  );

  runApp(const IntegradorApp());
}