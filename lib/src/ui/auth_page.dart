import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  StreamSubscription<User?>? _authSubscription;

  bool _isWorking = false;
  String? _message;

  void _log(String message) {
    developer.log(message, name: 'PhotoDukan.AuthPage');
  }

  bool get _supportsGoogleSignIn {
    if (kIsWeb) {
      return true;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _log('initState currentUser=${widget.authRepository.currentUser?.uid}');
    _authSubscription = widget.authRepository.authStateChanges().listen((user) {
      _log('authStateChanges user=${user?.uid}');
      if (user == null) {
        return;
      }

      unawaited(_syncRestoredSession());
    });
  }

  @override
  void dispose() {
    _log('dispose');
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncRestoredSession() async {
    _log('_syncRestoredSession start');
    try {
      await widget.authRepository.syncCurrentUser();
      _log('_syncRestoredSession success');
    } catch (error) {
      _log('_syncRestoredSession failure error=$error');
      _setMessage(_describeError(error));
    }
  }

  Future<void> _signInWithGoogle() async {
    _log('_signInWithGoogle pressed');
    setState(() {
      _isWorking = true;
      _message = null;
    });

    try {
      await widget.authRepository.signInWithGoogle();
      _log('_signInWithGoogle completed successfully');
      _setMessage('Signed in.');
    } catch (error) {
      _log('_signInWithGoogle failed error=$error');
      _setMessage(_describeError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _setMessage(String value) {
    if (!mounted) {
      return;
    }

    _log('_setMessage value=$value');

    setState(() {
      _message = value;
    });
  }

  String _describeError(Object error) {
    final rawError = error.toString().toUpperCase();
    if (rawError.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase auth is not configured for this Android app yet. Add the SHA-1 and SHA-256 fingerprints for com.photodukan.app in Firebase, download a fresh google-services.json, then rebuild.';
    }

    if (error is UnsupportedError) {
      return error.message ?? 'This mode is not available here.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'aborted-by-user':
          return 'Sign in cancelled.';
        case 'invalid-phone-number':
          return 'That phone number looks wrong.';
        case 'invalid-verification-code':
          return 'That code is not valid.';
        case 'session-expired':
          return 'That code expired. Request a new one.';
        case 'too-many-requests':
          return 'Too many attempts. Try again shortly.';
        case 'network-request-failed':
          return 'Network issue. Try again.';
        default:
          return error.message ?? error.code;
      }
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authRepository.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F1E8), Color(0xFFE5C39C)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -40,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6ED).withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: -70,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD78E58).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: user == null
                            ? _buildAuthCard(context)
                            : _SignedInCard(
                                user: user,
                                onSignOut: widget.authRepository.signOut,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.92),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB85C38),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PhotoDukan',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Continue with Google.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A5545),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildGooglePane(theme),
            if (_message != null) ...[
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E8DB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    _message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5C4635),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGooglePane(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Google sign in',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _supportsGoogleSignIn
              ? 'One tap, no password.'
              : 'Use a supported build for Google sign in.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6A5545),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isWorking || !_supportsGoogleSignIn ? null : _signInWithGoogle,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1F1A17),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF1F1A17),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(_isWorking ? 'Working...' : 'Continue with Google'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.onSignOut});

  final User user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final label = user.displayName ?? user.phoneNumber ?? user.email ?? 'Ready';
    final avatarText = label.isEmpty ? 'P' : label.substring(0, 1).toUpperCase();

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFFB85C38),
              backgroundImage: user.photoURL == null ? null : NetworkImage(user.photoURL!),
              child: user.photoURL == null
                  ? Text(
                      avatarText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              'You are in',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF6A5545),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onSignOut,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}