import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (_isRegisterMode) {
        await widget.authRepository.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await widget.authRepository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _message = _isRegisterMode
            ? 'Account created and synced to the backend.'
            : 'Signed in and synced to the backend.';
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _message = error.message ?? error.code;
      });
    } on ApiException catch (error) {
      setState(() {
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PhotoDukan Auth',
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Firebase authenticates the user, then the backend verifies the ID token and upserts a Postgres user record through Prisma.',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (user != null)
                        _SignedInCard(
                          user: user,
                          onSignOut: widget.authRepository.signOut,
                        )
                      else
                        _buildAuthForm(context),
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  final password = value?.trim() ?? '';
                  if (password.length < 6) {
                    return 'Passwords must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                  _isSubmitting
                      ? 'Working...'
                      : _isRegisterMode
                          ? 'Create account'
                          : 'Sign in',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                          _message = null;
                        });
                      },
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Sign in'
                      : 'Need an account? Register',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Backend URL is controlled with API_BASE_URL.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.onSignOut});

  final User user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Signed in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('UID: ${user.uid}'),
            const SizedBox(height: 8),
            Text('Email: ${user.email ?? 'unknown'}'),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onSignOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}