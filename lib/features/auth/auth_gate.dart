import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../settings/models/app_user_model.dart';
import 'data/auth_repository.dart';
import 'pages/login_page.dart';

/// Porta de entrada do app.
///
/// Observa o estado de autenticação e escolhe qual tela mostrar:
/// - sem usuário: LoginPage;
/// - com usuário: HomePage.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = AuthRepository();

  Future<void> _handleSignOut() async {
    await _authRepository.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: _authRepository.authStateChanges(),
      initialData: _authRepository.currentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // Sem token/perfil válido, o app começa pelo login.
          return const LoginPage();
        }

        // Usuário autenticado, libera a experiência principal.
        return HomePage(
          user: user,
          onSignOut: _handleSignOut,
        );
      },
    );
  }
}
