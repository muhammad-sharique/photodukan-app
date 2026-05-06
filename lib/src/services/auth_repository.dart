import 'package:firebase_auth/firebase_auth.dart';

import 'api_client.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth, required ApiClient apiClient})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _apiClient = apiClient;

  final FirebaseAuth _firebaseAuth;
  final ApiClient _apiClient;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncUser(credential.user);
  }

  Future<void> register({required String email, required String password}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _syncUser(credential.user);
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> _syncUser(User? user) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user session available.',
      );
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Failed to acquire a Firebase ID token.',
      );
    }

    await _apiClient.syncUser(idToken);
  }
}