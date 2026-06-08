import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../settings/models/app_user_model.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _useMock = Firebase.apps.isEmpty,
        _firebaseAuth = (firebaseAuth == null && Firebase.apps.isNotEmpty)
            ? FirebaseAuth.instance
            : firebaseAuth;

  final FirebaseAuth? _firebaseAuth;
  final bool _useMock;

  static AppUserModel? _currentMockUser = AppUserModel(
    id: 'mock_user_123',
    name: 'Nome de Teste',
    email: 'teste@bengalafc.com',
    avatarUrl: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final StreamController<AppUserModel?> _mockUserStreamController =
      StreamController<AppUserModel?>.broadcast();

  Stream<AppUserModel?> authStateChanges() async* {
    if (_useMock) {
      yield _currentMockUser;
      yield* _mockUserStreamController.stream;
      return;
    }
    yield* _firebaseAuth!.userChanges().map(_mapUser);
  }

  AppUserModel? currentUser() {
    if (_useMock) return _currentMockUser;
    return _mapUser(_firebaseAuth!.currentUser);
  }

  Future<AppUserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      _currentMockUser = AppUserModel(
        id: 'mock_user_123',
        name: name,
        email: email,
        avatarUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockUserStreamController.add(_currentMockUser);
      return _currentMockUser!;
    }
    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
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

      await _syncUserDocument(appUser);
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFromCode(error));
    }
  }

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    if (_useMock) {
      _currentMockUser = AppUserModel(
        id: 'mock_user_123',
        name: _currentMockUser?.name ?? 'Nome de Teste',
        email: email,
        avatarUrl: _currentMockUser?.avatarUrl,
        createdAt: _currentMockUser?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockUserStreamController.add(_currentMockUser);
      return _currentMockUser!;
    }
    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final appUser = _mapUser(credential.user);
      if (appUser == null) {
        throw const AuthException('Nao foi possivel carregar o usuario.');
      }

      await _syncUserDocument(appUser);
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFromCode(error));
    }
  }

  Future<void> signOut() async {
    if (_useMock) {
      _currentMockUser = null;
      _mockUserStreamController.add(null);
      return;
    }
    await _firebaseAuth!.signOut();
  }

  Future<AppUserModel> updateProfile({
    String? name,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    if (_useMock) {
      if (_currentMockUser == null) {
        throw const AuthException('Nenhum usuário logado.');
      }
      _currentMockUser = AppUserModel(
        id: _currentMockUser!.id,
        name: name ?? _currentMockUser!.name,
        email: _currentMockUser!.email,
        avatarUrl: clearAvatar ? null : avatarUrl ?? _currentMockUser!.avatarUrl,
        createdAt: _currentMockUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      _mockUserStreamController.add(_currentMockUser);
      return _currentMockUser!;
    }
    try {
      final user = _firebaseAuth!.currentUser;
      if (user == null) {
        throw const AuthException('Nenhum usuário logado.');
      }

      if (name != null && name.trim().isNotEmpty) {
        await user.updateDisplayName(name.trim()).timeout(
              const Duration(seconds: 15),
            );
      }
      if (avatarUrl != null) {
        await user.updatePhotoURL(avatarUrl).timeout(
              const Duration(seconds: 15),
            );
      } else if (clearAvatar) {
        await user.updatePhotoURL(null).timeout(
              const Duration(seconds: 15),
            );
      }

      await user.reload().timeout(const Duration(seconds: 15));
      final updatedUser = _firebaseAuth.currentUser;
      final appUser = _mapUser(updatedUser);
      if (appUser == null) {
        throw const AuthException('Erro ao atualizar dados do usuário.');
      }
      await _syncUserDocument(appUser);
      return appUser;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFromCode(error));
    }
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

  Future<void> _syncUserDocument(AppUserModel user) async {
    if (_useMock) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Auth should keep working even if the ranking profile mirror is unavailable.
    }
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
