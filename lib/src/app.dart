import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config/firebase_runtime_config.dart';
import 'services/api_client.dart';
import 'services/auth_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'ui/auth_page.dart';
import 'ui/signed_in_shell.dart';

class PhotoDukanApp extends StatefulWidget {
  const PhotoDukanApp({super.key, FirebaseBootstrap? bootstrap})
    : _bootstrap = bootstrap;

  final FirebaseBootstrap? _bootstrap;

  @override
  State<PhotoDukanApp> createState() => _PhotoDukanAppState();
}

class _PhotoDukanAppState extends State<PhotoDukanApp> {
  late final Future<FirebaseBootstrapResult> _bootstrapFuture =
      (widget._bootstrap ?? FirebaseBootstrap()).initialize();
  late final ApiClient _apiClient = ApiClient(baseUrl: FirebaseRuntimeConfig.apiBaseUrl);
  late final AuthRepository _authRepository = AuthRepository(apiClient: _apiClient);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoDukan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB85C38),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5EFE6),
        useMaterial3: true,
      ),
      home: FutureBuilder<FirebaseBootstrapResult>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _LoadingScreen();
          }

          final result = snapshot.data!;
          if (!result.isConfigured || !result.isReady) {
            return _SetupScreen(message: result.message);
          }

          return StreamBuilder<User?>(
            stream: _authRepository.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }

              if (authSnapshot.data == null) {
                return AuthPage(authRepository: _authRepository);
              }

              return SignedInShellPage(
                authRepository: _authRepository,
                apiClient: _apiClient,
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6EFE6), Color(0xFFE8D2BA)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 0,
              color: Colors.white.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup needed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(message, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}