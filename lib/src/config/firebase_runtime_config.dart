import 'package:firebase_core/firebase_core.dart';

class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const androidClientId = String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID');
  static const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
  static const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.2:3000',
  );

  static bool get isConfigured {
    return apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty;
  }

  static FirebaseOptions get options {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
      androidClientId: androidClientId.isEmpty ? null : androidClientId,
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
      measurementId: measurementId.isEmpty ? null : measurementId,
    );
  }
}