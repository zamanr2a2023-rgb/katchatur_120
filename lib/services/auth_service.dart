import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'membership_service.dart';
import 'visit_welcome_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _idTokenSub;
  bool _sessionGuardStarted = false;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<User?> get idTokenChanges => _auth.idTokenChanges();

  /// Kick / Auth-disable are validated on app resume via [verifySessionOnResume].
  /// Do not call getIdToken(true) from idTokenChanges — that can loop.
  void startSessionGuard() {
    if (_sessionGuardStarted) return;
    _sessionGuardStarted = true;

    _idTokenSub?.cancel();
    _idTokenSub = _auth.idTokenChanges().listen((user) {
      if (user == null) {
        VisitWelcomeService.instance.disposeForSignOut();
      }
    });
  }

  /// Call on app resume to re-validate the ID token after Kick / disable.
  Future<bool> verifySessionOnResume() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      if (_isSessionRevoked(e) || e.code == 'user-disabled') {
        if (kDebugMode) {
          debugPrint('AuthService.verifySessionOnResume: ${e.code}');
        }
        await signOut();
        return false;
      }
      // Network blips — keep local session; membership snapshot still gates UI.
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.verifySessionOnResume error: $e');
      }
      return true;
    }
  }

  bool _isSessionRevoked(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'user-disabled':
      case 'user-not-found':
      case 'id-token-revoked':
      case 'session-cookie-revoked':
        return true;
      default:
        return false;
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    VisitWelcomeService.instance.disposeForSignOut();
    await _auth.signOut();
  }

  /// Reauthenticates, deletes the membership profile, then deletes the Auth user.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    final email = user.email?.trim() ?? '';
    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'This account has no email to confirm deletion.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    try {
      await MembershipService.instance.deleteCurrentMembership();
    } catch (_) {
      // Continue so the Auth account is still removed.
    }

    await user.delete();
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates Auth user, uploads proof, then creates Pending `users/{uid}`.
  Future<UserCredential> registerWithMembership({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required XFile proofFile,
    required String reviewPlatform,
  }) async {
    final credential = await createUserWithEmailPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Registration failed. Please try again.');
    }

    await user.updateDisplayName(fullName.trim());

    try {
      await MembershipService.instance.createMembershipWithProof(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        proofFile: proofFile,
        reviewPlatform: reviewPlatform,
      );
    } catch (e) {
      // Do not leave orphan Auth without surfacing failure.
      if (kDebugMode) {
        debugPrint('AuthService.registerWithMembership profile failed: $e');
      }
      try {
        await user.delete();
      } catch (deleteError) {
        if (kDebugMode) {
          debugPrint(
            'AuthService: could not roll back Auth user after failed membership: $deleteError',
          );
        }
        await signOut();
      }
      rethrow;
    }

    return credential;
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static String mapFirebaseErrorToMessage(Object error) {
    if (error is FirebaseAuthException) {
      final message = (error.message ?? '').toLowerCase();
      // Identity Platform beforeCreate blocklist
      if (message.contains('blocked') ||
          message.contains('blocklist') ||
          message.contains('blocked_identifiers')) {
        return 'This email is blocked from registering.';
      }

      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account is disabled or blocked. Please contact support.';
        case 'user-not-found':
          return 'No account found for this email. Please create an account first.';
        case 'missing-email':
          return 'Please enter your email address.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Incorrect email or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Your password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Email sign-in is not enabled yet. Please enable it in Firebase Authentication.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'requires-recent-login':
          return 'Please log in again, then try deleting your account.';
        case 'user-mismatch':
          return 'This password does not match the signed-in account.';
        case 'internal-error':
          if (message.contains('block')) {
            return 'This email is blocked from registering.';
          }
          return 'Something went wrong. Please try again.';
        default:
          if (message.contains('block')) {
            return 'This email is blocked from registering.';
          }
          return 'Something went wrong. Please try again.';
      }
    }

    if (error is TimeoutException) {
      return 'This is taking too long. Please check your connection and try again.';
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Could not save membership. Check Firestore / Storage rules.';
      }
      if (error.code == 'unauthorized' || error.code == 'unauthenticated') {
        return 'Not signed in. Please try registering again.';
      }
      if (error.message?.isNotEmpty == true) {
        return error.message!;
      }
    }

    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('blocked')) {
      return 'This email is blocked from registering.';
    }
    if (lower.contains('5 mb') || lower.contains('5 mi')) {
      return 'Image must be 5 MB or smaller.';
    }
    if (lower.contains('unsupported image')) {
      return 'Unsupported image type. Use jpg, jpeg, png, or webp.';
    }
    if (lower.contains('permission-denied') ||
        lower.contains('cloud_firestore') ||
        lower.contains('firebase_storage')) {
      return 'Could not save membership. Please try again or contact support.';
    }
    if (error is StateError && error.message.isNotEmpty) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}
