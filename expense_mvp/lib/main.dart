import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si configuraste Firebase, descomenta:
  // import 'firebase_options.dart';
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await Firebase.initializeApp();
  } catch (_) {
    debugPrint('⚠️ Firebase no configurado. App en modo demo (auth + sync simuladas).');
  }

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ExpenseApp()));
}