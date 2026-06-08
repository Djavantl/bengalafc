import 'package:flutter/material.dart';
import '../../../core/services/pkce_helper.dart';
import '../data/auth_repository.dart';
import 'web_auth_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  Future<void> _loginWithPkce() async {
    setState(() => _isLoading = true);

    try {
      final codeVerifier = PkceHelper.generateCodeVerifier();
      final codeChallenge = PkceHelper.generateCodeChallenge(codeVerifier);
      final authUrl = _authRepository.getAuthorizationUrl(codeChallenge);
      const redirectUri = 'http://localhost:8000/callback';

      if (!mounted) return;
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => WebAuthPage(
            authUrl: authUrl,
            redirectUri: redirectUri,
          ),
        ),
      );

      if (code == null) {
        setState(() => _isLoading = false);
        return;
      }

      await _authRepository.signInWithCode(
        code: code,
        codeVerifier: codeVerifier,
      );

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (error) {
      _showError(error.message);
    } catch (e) {
      _showError('Erro ao realizar login. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openWebsiteRegister() {
    final registerUrl = '${_authRepository.getAuthorizationUrl("dummy").split("/o/authorize/").first}/';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WebAuthPage(
          authUrl: registerUrl,
          redirectUri: 'http://localhost:8000/callback',
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(Icons.sports_soccer, size: 80, color: cs.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Bengala FC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O Fantasy Game oficial do Bengala',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Autenticando com o servidor...',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loginWithPkce,
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Entrar com o Bengala FC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openWebsiteRegister,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text(
                        'Criar conta no site',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
