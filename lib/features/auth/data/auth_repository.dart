import 'dart:async';
import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../../settings/models/app_user_model.dart';

class AuthRepository {
  AuthRepository();

  static AppUserModel? _currentUser;
  static final StreamController<AppUserModel?> _userStreamController =
      StreamController<AppUserModel?>.broadcast();

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

  String getAuthorizationUrl(String challenge) {
    final baseUrl = ApiClient.instance.baseUrl;
    return '$baseUrl/o/authorize/?response_type=code&client_id=bengalafc-mobile&redirect_uri=http://localhost:8000/callback&code_challenge=$challenge&code_challenge_method=S256';
  }

  Future<AppUserModel> signInWithCode({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'http://localhost:8000/callback',
        'client_id': 'bengalafc-mobile',
        'code_verifier': codeVerifier,
      };

      final response = await ApiClient.instance.post(
        '/o/token/',
        body,
        requireAuth: false,
        isJson: false,
      );

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'] as String;

      await ApiClient.instance.saveToken(accessToken);

      final user = await _fetchProfile();
      _currentUser = user;
      _userStreamController.add(_currentUser);
      return user;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw const AuthException('Erro ao autenticar com o código do servidor.');
    }
  }

  Future<void> signOut() async {
    await ApiClient.instance.clearToken();
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<AppUserModel> updateProfile({
    String? name,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) {
        final parts = name.trim().split(' ');
        body['first_name'] = parts.first;
        body['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      if (clearAvatar) {
        body['photo'] = null;
      } else if (avatarUrl != null) {
        body['photo'] = avatarUrl;
      }

      await ApiClient.instance.patch(
        '/api/users/update_profile/',
        body,
      );

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
    final response = await ApiClient.instance.get('/api/users/me/');
    final data = jsonDecode(response.body);

    final id = data['id']?.toString() ?? '';
    final email = data['email'] as String?;
    final firstName = data['first_name'] as String? ?? '';
    final lastName = data['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final displayName = name.isNotEmpty ? name : (data['username'] as String? ?? 'Usuário');
    final avatar = data['photo'] as String?;
    
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
