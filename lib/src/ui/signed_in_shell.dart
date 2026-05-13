import 'package:flutter/material.dart';

import '../features/product_images/product_images_controller.dart';
import '../features/product_images/product_images_repository.dart';
import '../features/product_images/product_images_screen.dart';
import '../services/api_client.dart';
import '../services/auth_repository.dart';

class SignedInShellPage extends StatefulWidget {
  const SignedInShellPage({
    super.key,
    required this.authRepository,
    required this.apiClient,
  });

  final AuthRepository authRepository;
  final ApiClient apiClient;

  @override
  State<SignedInShellPage> createState() => _SignedInShellPageState();
}

class _SignedInShellPageState extends State<SignedInShellPage> {
  late final ProductImagesController _controller = ProductImagesController(
    repository: ProductImagesRepository(
      apiClient: widget.apiClient,
      loadIdToken: widget.authRepository.getIdToken,
    ),
  );

  late Future<void> _prepareFuture = _prepare();

  Future<void> _prepare() async {
    await widget.authRepository.syncCurrentUser();
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _prepareFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ShellLoadingState();
        }

        if (snapshot.hasError) {
          return _ShellErrorState(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _prepareFuture = _prepare();
              });
            },
            onSignOut: widget.authRepository.signOut,
          );
        }

        return Scaffold(
          body: ProductImagesScreen(
            controller: _controller,
            currentUser: widget.authRepository.currentUser,
            onSignOut: widget.authRepository.signOut,
          ),
        );
      },
    );
  }
}

class _ShellLoadingState extends StatelessWidget {
  const _ShellLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F1E8), Color(0xFFE8D2BA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ShellErrorState extends StatelessWidget {
  const _ShellErrorState({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F1E8), Color(0xFFE8D2BA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(24),
              color: Colors.white.withValues(alpha: 0.94),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We could not load your workspace.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(message),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: onRetry,
                            child: const Text('Retry'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSignOut,
                            child: const Text('Sign out'),
                          ),
                        ),
                      ],
                    ),
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