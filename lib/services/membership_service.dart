import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../features/membership/data/member_profile.dart';
import '../features/membership/data/membership_status.dart';
import 'membership_proof_storage.dart';

class MembershipService {
  MembershipService._();

  static final MembershipService instance = MembershipService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Auth-only placeholder for loading UI — never treated as a live membership.
  MemberProfile profileFromAuth(
    User user, {
    String? fullName,
    String? phone,
  }) {
    final now = user.metadata.creationTime ?? DateTime.now();
    final memberId = _generateMemberId(user.uid, now);
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Bajatzu Member');

    return MemberProfile(
      uid: user.uid,
      fullName: name,
      email: user.email ?? '',
      phone: phone?.trim() ?? '',
      status: MembershipStatus.pending,
      memberId: memberId,
      tier: 'Bajatzu Member',
      createdAt: now,
      qrPayload: 'bajatzu:$memberId:${user.uid}',
    );
  }

  /// Creates `users/{uid}` after Auth + proof upload.
  /// Always writes `status: "Pending"`. Never sets discount / role / reviewed*.
  Future<MemberProfile> createMembership({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required String reviewProofPath,
    required String reviewPlatform,
  }) async {
    if (!ReviewPlatform.isValid(reviewPlatform)) {
      throw StateError('reviewPlatform must be google or tripadvisor.');
    }
    if (reviewProofPath.trim().isEmpty ||
        !reviewProofPath.startsWith('membership_proofs/')) {
      throw StateError('reviewProofPath must be a Storage path.');
    }

    final now = DateTime.now();
    final memberId = _generateMemberId(uid, now);
    final profile = MemberProfile(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      status: MembershipStatus.pending,
      memberId: memberId,
      tier: 'Bajatzu Member',
      createdAt: now,
      qrPayload: 'bajatzu:$memberId:$uid',
      reviewProofPath: reviewProofPath,
      reviewPlatform: reviewPlatform,
      submittedAt: now,
    );

    await _users
        .doc(uid)
        .set(
          profile.toCreateMap(
            reviewProofPath: reviewProofPath,
            reviewPlatform: reviewPlatform,
          ),
        )
        .timeout(const Duration(seconds: 15));

    return profile;
  }

  /// Upload new proof + create Pending membership (signup).
  Future<MemberProfile> createMembershipWithProof({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required XFile proofFile,
    required String reviewPlatform,
  }) async {
    final path = await MembershipProofStorage.instance.uploadProof(
      uid: uid,
      file: proofFile,
    );
    return createMembership(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      reviewProofPath: path,
      reviewPlatform: reviewPlatform,
    );
  }

  Future<MemberProfile?> getMembership(String uid) async {
    try {
      final snap = await _users
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 10));
      if (!snap.exists || snap.data() == null) return null;
      return MemberProfile.fromMap(uid, snap.data()!);
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint('MembershipService.getMembership failed: ${e.code} $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  /// Live membership doc while signed in. Prefer snapshots for Approve unlock.
  Stream<MemberProfile?> watchCurrentMembership() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _users.doc(user.uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return MemberProfile.fromMap(user.uid, snap.data()!);
    }).handleError((Object error, StackTrace stack) {
      if (kDebugMode) {
        debugPrint('MembershipService.watchCurrentMembership error: $error');
        debugPrint('$stack');
      }
      throw error;
    });
  }

  /// Rejected → Pending with a **new** Storage object. Clears rejectionReason.
  Future<void> resubmitProof({
    required XFile proofFile,
    required String reviewPlatform,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    if (!ReviewPlatform.isValid(reviewPlatform)) {
      throw StateError('reviewPlatform must be google or tripadvisor.');
    }

    final existing = await getMembership(user.uid);
    if (existing == null) {
      throw StateError('Membership profile not found.');
    }
    if (existing.status != MembershipStatus.rejected) {
      throw StateError('Resubmit is only allowed from Rejected status.');
    }

    final path = await MembershipProofStorage.instance.uploadProof(
      uid: user.uid,
      file: proofFile,
    );

    final previousCount = existing.resubmissionCount ?? 0;

    await _users.doc(user.uid).update({
      'status': MembershipStatus.pending,
      'reviewProofPath': path,
      'reviewPlatform': reviewPlatform,
      'submittedAt': FieldValue.serverTimestamp(),
      'resubmissionCount': previousCount + 1,
      'rejectionReason': FieldValue.delete(),
    }).timeout(const Duration(seconds: 15));
  }

  /// Profile edits while Active — never includes `status` or admin fields.
  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }

    final email = user.email?.trim() ?? '';

    if (user.displayName != fullName.trim()) {
      await user.updateDisplayName(fullName.trim());
      await user.reload();
    }

    await _users.doc(user.uid).update({
      'fullName': fullName.trim(),
      'email': email,
      'phone': phone.trim(),
    }).timeout(const Duration(seconds: 10));
  }

  Future<void> deleteCurrentMembership() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await _users.doc(user.uid).delete().timeout(const Duration(seconds: 8));
  }

  String _generateMemberId(String uid, DateTime now) {
    final seed = uid.hashCode.abs() ^ now.millisecondsSinceEpoch;
    final number = (seed % 9000) + 1000;
    return 'BJZ-$number';
  }
}
