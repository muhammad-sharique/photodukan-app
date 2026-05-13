import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required ApiClient apiClient,
  })
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: const [
              'email',
              'https://www.googleapis.com/auth/user.phonenumbers.read',
            ],
          ),
      _apiClient = apiClient;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiClient _apiClient;
  Future<void>? _pendingSync;
  String? _pendingSyncUid;

  void _log(String message) {
    developer.log(message, name: 'PhotoDukan.AuthRepository');
  }

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithGoogle() async {
    _log('signInWithGoogle start platform=${defaultTargetPlatform.name} isWeb=$kIsWeb');
    late final UserCredential credential;
    String? accessToken;

    if (kIsWeb) {
      credential = await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    } else {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        _log('signInWithGoogle cancelled by user before Firebase credential exchange');
        throw FirebaseAuthException(
          code: 'aborted-by-user',
          message: 'Google sign in was cancelled.',
        );
      }

      _log('signInWithGoogle google account selected email=${account.email} id=${account.id}');

      final authentication = await account.authentication;
      accessToken = authentication.accessToken;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );

      _log(
        'signInWithGoogle credential ready hasAccessToken=${authentication.accessToken != null} hasIdToken=${authentication.idToken != null}',
      );

      credential = await _firebaseAuth.signInWithCredential(googleCredential);
    }

    _log('signInWithGoogle firebase success uid=${credential.user?.uid} email=${credential.user?.email}');

    final phoneNumber = await _fetchGooglePhoneNumber(
      accessToken: accessToken,
      firebaseUser: credential.user,
    );
    _log('signInWithGoogle resolved phoneNumber=${phoneNumber ?? 'none'}');

    await _syncSignedInUser(credential.user, phoneNumber: phoneNumber);
  }

  Future<PhoneOtpSession> requestPhoneOtp({
    required String phoneNumber,
    int? forceResendingToken,
  }) async {
    if (kIsWeb) {
      _log('requestPhoneOtp rejected because platform is web');
      throw UnsupportedError('Phone OTP is available on mobile builds only.');
    }

    _log('requestPhoneOtp start phoneNumber=$phoneNumber resendToken=$forceResendingToken');

    final completer = Completer<PhoneOtpSession>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          _log('requestPhoneOtp verificationCompleted received instant credential');
          final result = await _firebaseAuth.signInWithCredential(credential);
          _log('requestPhoneOtp instant sign in success uid=${result.user?.uid}');
          await _syncSignedInUser(
            result.user,
            phoneNumber: result.user?.phoneNumber,
          );
          if (!completer.isCompleted) {
            completer.complete(const PhoneOtpSession.completed());
          }
        } catch (error, stackTrace) {
          _log('requestPhoneOtp verificationCompleted sync failure error=$error');
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (error) {
        _log('requestPhoneOtp verificationFailed code=${error.code} message=${error.message}');
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (verificationId, resendToken) {
        _log('requestPhoneOtp codeSent verificationId=$verificationId resendToken=$resendToken');
        if (!completer.isCompleted) {
          completer.complete(
            PhoneOtpSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _log('requestPhoneOtp codeAutoRetrievalTimeout verificationId=$verificationId');
        if (!completer.isCompleted) {
          completer.complete(PhoneOtpSession(verificationId: verificationId));
        }
      },
    );

    return completer.future;
  }

  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    _log('verifyPhoneOtp start verificationId=$verificationId codeLength=${smsCode.length}');
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    _log('verifyPhoneOtp firebase success uid=${result.user?.uid}');
    await _syncSignedInUser(
      result.user,
      phoneNumber: result.user?.phoneNumber,
    );
  }

  Future<void> syncCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      _log('syncCurrentUser skipped because no current user exists');
      return;
    }

    _log('syncCurrentUser start uid=${user.uid}');

    await _syncSignedInUser(user, phoneNumber: user.phoneNumber);
  }

  Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user session available.',
      );
    }

    final idToken = await user.getIdToken(forceRefresh);
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Failed to acquire a Firebase ID token.',
      );
    }

    return idToken;
  }

  Future<void> signOut() async {
    _log('signOut start currentUid=${_firebaseAuth.currentUser?.uid}');
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
    _log('signOut complete');
  }

  Future<void> _syncUser(User? user, {String? phoneNumber}) async {
    if (user == null) {
      _log('_syncUser aborted because user is null');
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user session available.',
      );
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      _log('_syncUser failed because Firebase returned an empty ID token for uid=${user.uid}');
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Failed to acquire a Firebase ID token.',
      );
    }

    _log('syncUser start uid=${user.uid} email=${user.email} phoneNumber=${phoneNumber ?? user.phoneNumber ?? 'none'}');

    await _apiClient.syncUser(
      idToken,
      phoneNumber: phoneNumber ?? user.phoneNumber,
    );
    _log('syncUser success uid=${user.uid}');
  }

  Future<void> _syncSignedInUser(User? user, {String? phoneNumber}) {
    if (user == null) {
      _log('_syncSignedInUser called with null user');
      return Future.error(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user session available.',
        ),
      );
    }

    if (_pendingSync != null && _pendingSyncUid == user.uid) {
      _log('_syncSignedInUser joining pending sync uid=${user.uid}');
      return _pendingSync!;
    }

    _log('_syncSignedInUser begin uid=${user.uid}');

    final future = _syncUser(user, phoneNumber: phoneNumber).catchError((Object error, StackTrace stackTrace) async {
      _log('_syncSignedInUser failure uid=${user.uid} error=$error');
      await _rollbackLocalSession();
      Error.throwWithStackTrace(error, stackTrace);
    });

    _pendingSyncUid = user.uid;
    _pendingSync = future.whenComplete(() {
      _log('_syncSignedInUser finished uid=${user.uid}');
      if (identical(_pendingSync, future)) {
        _pendingSync = null;
        _pendingSyncUid = null;
      }
    });

    return _pendingSync!;
  }

  Future<void> _rollbackLocalSession() async {
    _log('_rollbackLocalSession start currentUid=${_firebaseAuth.currentUser?.uid}');
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore provider cleanup failures; Firebase sign-out below is the hard stop.
    }

    await _firebaseAuth.signOut();
    _log('_rollbackLocalSession complete');
  }

  Future<String?> _fetchGooglePhoneNumber({
    required String? accessToken,
    required User? firebaseUser,
  }) async {
    if (firebaseUser?.phoneNumber case final existingPhone?) {
      return existingPhone;
    }

    if (accessToken == null || accessToken.isEmpty) {
      _log('_fetchGooglePhoneNumber skipped because access token is missing');
      return null;
    }

    final uri = Uri.parse(
      'https://people.googleapis.com/v1/people/me?personFields=phoneNumbers',
    );
    _log('_fetchGooglePhoneNumber request uri=$uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      _log(
        '_fetchGooglePhoneNumber response status=${response.statusCode} body=${response.body.length > 400 ? '${response.body.substring(0, 400)}...' : response.body}',
      );

      if (response.statusCode >= 400) {
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final phoneNumbers = json['phoneNumbers'];
      if (phoneNumbers is! List) {
        return null;
      }

      for (final entry in phoneNumbers) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }

        final canonicalForm = entry['canonicalForm']?.toString();
        if (canonicalForm != null && canonicalForm.isNotEmpty) {
          return canonicalForm;
        }

        final value = entry['value']?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (error) {
      _log('_fetchGooglePhoneNumber failed error=$error');
    }

    return null;
  }
}

class PhoneOtpSession {
  const PhoneOtpSession({
    required this.verificationId,
    this.resendToken,
    this.completedInstantly = false,
  });

  const PhoneOtpSession.completed()
    : verificationId = '',
      resendToken = null,
      completedInstantly = true;

  final String verificationId;
  final int? resendToken;
  final bool completedInstantly;

  bool get requiresSmsCode => !completedInstantly && verificationId.isNotEmpty;
}