import 'package:firebase_auth/firebase_auth.dart';

import '../../settings/models/app_user_model.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<AppUserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  AppUserModel? currentUser() {
    return _mapUser(_firebaseAuth.currentUser);
  }

  Future<AppUserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();

      final user = _firebaseAuth.currentUser ?? credential.user;
      final appUser = _mapUser(user);
      if (appUser == null) {
        throw const AuthException('Nao foi possivel criar o usuario.');
      }

      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFromCode(error));
    }
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final appUser = _mapUser(credential.user);
      if (appUser == null) {
        throw const AuthException('Nao foi possivel carregar o usuario.');
      }

      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFromCode(error));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  AppUserModel? _mapUser(User? user) {
    if (user == null) return null;

    final now = DateTime.now();
    return AppUserModel(
      id: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email?.split('@').first ?? 'Usuario',
      email: user.email,
      avatarUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: user.metadata.lastSignInTime ?? now,
    );
  }

  String _messageFromCode(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Este e-mail ja esta cadastrado.';
      case 'invalid-email':
        return 'Informe um e-mail valido.';
      case 'invalid-api-key':
      case 'app-not-authorized':
      case 'configuration-not-found':
        return 'Configuracao do Firebase Auth nao encontrada para este app.';
      case 'unauthorized-domain':
        return 'Dominio do Chrome nao autorizado no Firebase Auth.';
      case 'operation-not-allowed':
        return 'Login por e-mail e senha nao esta ativado no Firebase.';
      case 'weak-password':
        return 'A senha esta muito fraca.';
      case 'user-disabled':
        return 'Este usuario foi desativado.';
      case 'missing-password':
        return 'Informe sua senha.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-mail ou senha invalidos.';
      case 'network-request-failed':
        return 'Sem conexao com a internet.';
      default:
        return 'Nao foi possivel autenticar (${error.code}). Tente novamente.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
