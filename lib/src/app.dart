import 'package:flutter/material.dart';

import 'config/firebase_runtime_config.dart';
import 'services/api_client.dart';
import 'services/auth_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'ui/auth_page.dart';

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

          return AuthPage(
            authRepository: AuthRepository(
              apiClient: ApiClient(baseUrl: FirebaseRuntimeConfig.apiBaseUrl),
            ),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase setup required',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase now initializes from firebase_options.dart. Only API_BASE_URL needs runtime configuration if you want a non-default backend URL.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}