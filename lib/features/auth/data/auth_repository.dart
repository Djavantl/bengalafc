import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/api_client.dart';
import '../../settings/models/app_user_model.dart';

/// Camada responsável por autenticação e perfil do usuário.
///
/// As telas chamam este repository, e ele centraliza:
/// - login OAuth em `/o/token/`;
/// - cadastro em `/api/users/`;
/// - busca do usuário logado em `/api/users/me/`;
/// - atualização de perfil em `/api/users/update_profile/`.
class AuthRepository {
  AuthRepository();

  static AppUserModel? _currentUser;
  static final StreamController<AppUserModel?> _userStreamController =
      StreamController<AppUserModel?>.broadcast();

  /// Stream observado pelo AuthGate para decidir entre LoginPage e HomePage.
  Stream<AppUserModel?> authStateChanges() async* {
    if (_currentUser == null && ApiClient.instance.isAuthenticated) {
      try {
        _currentUser = await _fetchProfile();
      } catch (_) {
        await ApiClient.instance.clearToken();
      }
    }
    yield _currentUser;
    yield* _userStreamController.stream;
  }

  AppUserModel? currentUser() {
    return _currentUser;
  }

  String get _clientId => dotenv.env['OAUTH_CLIENT_ID']?.trim() ?? '';

  String get _clientSecret => dotenv.env['OAUTH_CLIENT_SECRET']?.trim() ?? '';

  void _validateOAuthConfig() {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw const AuthException(
        'Configure OAUTH_CLIENT_ID e OAUTH_CLIENT_SECRET no .env do app.',
      );
    }
  }

  Future<AppUserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _validateOAuthConfig();

      // Password grant: a API recebe email/senha e devolve access_token.
      final response = await ApiClient.instance.post(
        '/o/token/',
        {
          'grant_type': 'password',
          'username': email.trim(),
          'password': password,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        requireAuth: false,
        isJson: false,
      );

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String;

      await ApiClient.instance.saveToken(accessToken);

      // Depois do token, busca os dados reais do usuário para preencher a Home.
      final user = await _fetchProfile();
      _currentUser = user;
      _userStreamController.add(_currentUser);
      return user;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException('Erro ao autenticar com email e senha.');
    }
  }

  Future<AppUserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Primeiro cria o usuário no backend.
      await ApiClient.instance.post(
        '/api/users/',
        {
          'username': email.trim(),
          'email': email.trim(),
          'password': password,
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
        },
        requireAuth: false,
      );

      // Depois reutiliza o fluxo de login para salvar token e carregar perfil.
      return signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException('Erro ao criar conta.');
    }
  }

  Future<void> signOut() async {
    // Logout local: remove token salvo e avisa o AuthGate para voltar ao login.
    await ApiClient.instance.clearToken();
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<AppUserModel> updateProfile({
    String? name,
    String? avatarUrl,
    List<int>? avatarBytes,
    String? avatarFilename,
    bool clearAvatar = false,
  }) async {
    try {
      final body = <String, String>{};
      if (name != null) {
        final parts = name.trim().split(' ');
        body['first_name'] = parts.first;
        body['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      if (avatarBytes != null && avatarFilename != null) {
        await ApiClient.instance.patchMultipart(
          '/api/users/update_profile/',
          fields: body,
          fileField: 'photo',
          fileBytes: avatarBytes,
          filename: avatarFilename,
        );
      } else {
        final jsonBody = <String, dynamic>{...body};
        if (clearAvatar) {
          jsonBody['photo'] = null;
        } else if (avatarUrl != null) {
          jsonBody['photo'] = avatarUrl;
        }

        await ApiClient.instance.patch(
          '/api/users/update_profile/',
          jsonBody,
        );
      }

      final user = await _fetchProfile();
      _currentUser = user;
      _userStreamController.add(_currentUser);
      return user;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('Erro ao atualizar perfil.');
    }
  }

  Future<AppUserModel> _fetchProfile() async {
    // Endpoint usado após login/cadastro para montar o usuário local do app.
    final response = await ApiClient.instance.get('/api/users/me/');
    final data = jsonDecode(response.body);

    final id = data['id']?.toString() ?? '';
    final email = data['email'] as String?;
    final firstName = data['first_name'] as String? ?? '';
    final lastName = data['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final displayName =
        name.isNotEmpty ? name : (data['username'] as String? ?? 'Usuário');
    final avatar = (data['photo_url'] ?? data['photo']) as String?;

    String? fullAvatarUrl;
    if (avatar != null) {
      if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        fullAvatarUrl = avatar;
      } else {
        fullAvatarUrl = '${ApiClient.instance.baseUrl}$avatar';
      }
    }

    return AppUserModel(
      id: id,
      name: displayName,
      email: email,
      avatarUrl: fullAvatarUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
