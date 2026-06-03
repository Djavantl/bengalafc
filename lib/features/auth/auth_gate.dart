import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../settings/models/app_user_model.dart';
import 'data/firebase_auth_repository.dart';
import 'pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = FirebaseAuthRepository();

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
          return const LoginPage();
        }

        return HomePage(
          user: user,
          onSignOut: _handleSignOut,
        );
      },
    );
  }
}
