import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final instance = BiometricService._();
  BiometricService._();

  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();

  Future<bool> canUse() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a tus gastos',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> storeBiometricToken(String token) async {
    await _secure.write(key: 'bio_token', value: token);
  }

  Future<String?> readBiometricToken() async {
    return _secure.read(key: 'bio_token');
  }
}