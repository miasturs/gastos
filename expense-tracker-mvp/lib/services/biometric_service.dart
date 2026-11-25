import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> disponible() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> autenticar() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a tus gastos',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Error biométrico: $e');
      return false;
    }
  }
}