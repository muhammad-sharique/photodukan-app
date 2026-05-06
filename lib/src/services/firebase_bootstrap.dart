import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_runtime_config.dart';

class FirebaseBootstrap {
  Future<FirebaseBootstrapResult> initialize() async {
    if (!FirebaseRuntimeConfig.isConfigured) {
      return const FirebaseBootstrapResult(
        isConfigured: false,
        isReady: false,
        message:
            'Missing Firebase dart-defines. Provide FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and FIREBASE_PROJECT_ID.',
      );
    }

    try {
      await Firebase.initializeApp(options: FirebaseRuntimeConfig.options);
      return const FirebaseBootstrapResult(
        isConfigured: true,
        isReady: true,
        message: 'Firebase initialized.',
      );
    } on FirebaseException catch (error) {
      return FirebaseBootstrapResult(
        isConfigured: true,
        isReady: false,
        message: 'Firebase initialization failed: ${error.message ?? error.code}',
      );
    }
  }
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.isConfigured,
    required this.isReady,
    required this.message,
  });

  final bool isConfigured;
  final bool isReady;
  final String message;
}