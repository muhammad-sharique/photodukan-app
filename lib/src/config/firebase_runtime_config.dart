class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.2:3000',
  );
}