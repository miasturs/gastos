import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _demoController = StreamController<User?>.broadcast();
  User? _demoUser;

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return _demoController.stream;
    }
    return auth.authStateChanges();
  }

  Future<User?> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      // Modo demo: emite el usuario al StreamController
      if (email.contains('@') && password.length >= 6) {
        _demoUser = _DemoUser(email);
        _demoController.add(_demoUser);
        return _demoUser;
      }
      throw Exception('Credenciales inválidas');
    }
    final cred = await auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<User?> signUp(String email, String password) async {
    final auth = _auth;
    if (auth == null) return signIn(email, password);
    final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) {
      _demoUser = null;
      _demoController.add(null);
    } else {
      await auth.signOut();
    }
  }
}

class _DemoUser implements User {
  final String _email;
  _DemoUser(this._email);

  @override
  String? get email => _email;
  @override
  String get uid => 'demo-$_email';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}