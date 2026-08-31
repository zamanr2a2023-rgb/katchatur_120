import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'membership_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

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

  /// Creates Auth user + Firestore membership profile (with QR payload).
  Future<UserCredential> registerWithMembership({
    required String fullName,
    required String email,
    required String phone,
    required String password,
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
      await MembershipService.instance.createMembership(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
      );
    } catch (_) {
      // Registration still succeeds if Firestore is unavailable.
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
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account is disabled. Please contact support.';
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
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    if (error is TimeoutException) {
      return 'This is taking too long. Please check your connection and try again.';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied') ||
        message.contains('cloud_firestore')) {
      return 'Could not save membership. Please enable Cloud Firestore in Firebase.';
    }

    return 'Something went wrong. Please try again.';
  }
}

