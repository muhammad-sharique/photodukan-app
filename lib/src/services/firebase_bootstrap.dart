import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
    } on UnsupportedError catch (error) {
      return FirebaseBootstrapResult(
        isConfigured: true,
        isReady: false,
        message: error.message ?? 'Firebase is not configured for this platform.',
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