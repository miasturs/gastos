import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

// ⚠️ OPCIONAL: Rellena con tus credenciales de Supabase.
// Si las dejas vacías, la app funciona 100% en modo local.
const String supabaseUrl = '';
const String supabaseAnonKey = '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await DatabaseService.init();

  bool supabaseOk = false;
  try {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      supabaseOk = true;
    }
  } catch (e) {
    debugPrint('Supabase no configurado: $e');
  }

  runApp(ExpenseTrackerApp(supabaseEnabled: supabaseOk));
}

class ExpenseTrackerApp extends StatelessWidget {
  final bool supabaseEnabled;
  const ExpenseTrackerApp({super.key, required this.supabaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: supabaseEnabled ? const AuthGate() : const HomeScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}