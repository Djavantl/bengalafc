import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authRepository.signUpWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );
      } else {
        await _authRepository.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

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
                    _isSignUp
                        ? 'Crie sua conta para escalar seu time'
                        : 'Entre com sua conta Bengala FC',
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
                            'Conectando com o servidor...',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _firstNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (!_isSignUp) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe seu nome.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _lastNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Sobrenome',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (!_isSignUp) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe seu sobrenome.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'Informe seu email.';
                              if (!email.contains('@')) return 'Email inválido.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) return 'Informe sua senha.';
                              if (_isSignUp && password.length < 6) {
                                return 'A senha precisa ter pelo menos 6 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submit,
                            icon: Icon(
                              _isSignUp ? Icons.person_add_alt : Icons.login,
                            ),
                            label: Text(
                              _isSignUp ? 'Criar conta' : 'Entrar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() => _isSignUp = !_isSignUp);
                            },
                            child: Text(
                              _isSignUp ? 'Já tenho uma conta' : 'Não tenho conta',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
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
