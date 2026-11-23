import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.publishableKey, // ignore: deprecated_member_use
    );
  }

  runApp(const ChmsuLibraryApp());
}

class ChmsuLibraryApp extends StatelessWidget {
  const ChmsuLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHMSU Library',
      debugShowCheckedModeBanner: false,
      theme: buildChmsuTheme(),
      home: const AuthGate(),
    );
  }
}
