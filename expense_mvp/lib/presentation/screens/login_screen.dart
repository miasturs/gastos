import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final svc = ref.read(authServiceProvider);
      if (_isSignUp) {
        await svc.signUp(_email.text.trim(), _pass.text);
      } else {
        await svc.signIn(_email.text.trim(), _pass.text);
      }
      final bio = BiometricService.instance;
      if (await bio.canUse()) {
        await bio.storeBiometricToken('session-${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final bio = BiometricService.instance;
    final ok = await bio.authenticate();
    if (!ok) {
      setState(() => _error = 'Autenticación biométrica fallida');
      return;
    }
    final token = await bio.readBiometricToken();
    if (token == null) {
      setState(() => _error = 'No hay sesión biométrica guardada');
      return;
    }
    await ref.read(authServiceProvider).signIn('demo@local.app', '123456');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUp ? 'Crear cuenta' : 'Mis Gastos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || !v.contains('@')) return 'Email inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Registrarse' : 'Iniciar sesión'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(_isSignUp
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate'),
                  ),
                  const Divider(),
                  OutlinedButton.icon(
                    onPressed: _biometricLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Acceso con huella / Face ID'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}