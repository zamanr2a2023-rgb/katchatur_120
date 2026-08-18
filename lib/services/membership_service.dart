import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/membership/data/member_profile.dart';

class MembershipService {
  MembershipService._();

  static final MembershipService instance = MembershipService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

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
      status: 'Active',
      memberId: memberId,
      tier: 'Bajatzu Member',
      createdAt: now,
      qrPayload: 'bajatzu:$memberId:${user.uid}',
    );
  }

  Future<MemberProfile> createMembership({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final now = DateTime.now();
    final memberId = _generateMemberId(uid, now);
    final profile = MemberProfile(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      status: 'Active',
      memberId: memberId,
      tier: 'Bajatzu Member',
      createdAt: now,
      qrPayload: 'bajatzu:$memberId:$uid',
    );

    try {
      await _users
          .doc(uid)
          .set(profile.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Auth still works even if Firestore is not enabled yet.
    }
    return profile;
  }

  Future<MemberProfile?> getMembership(String uid) async {
    try {
      final snap = await _users
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));
      if (!snap.exists || snap.data() == null) return null;
      return MemberProfile.fromMap(uid, snap.data()!);
    } catch (_) {
      return null;
    }
  }

  /// Returns existing membership, or creates one for older accounts.
  Future<MemberProfile> getOrCreateCurrentMembership({
    String? fullName,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }

    final existing = await getMembership(user.uid);
    if (existing != null) return existing;

    return createMembership(
      uid: user.uid,
      fullName: fullName?.trim().isNotEmpty == true
          ? fullName!.trim()
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Bajatzu Member'),
      email: user.email ?? '',
      phone: phone?.trim() ?? '',
    );
  }

  /// Emits Auth fallback immediately, then Firestore when available.
  Stream<MemberProfile?> watchCurrentMembership() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    final fallback = profileFromAuth(user);
    yield fallback;

    try {
      final remote = await getOrCreateCurrentMembership()
          .timeout(const Duration(seconds: 8));
      yield remote;
    } catch (_) {
      // Keep Auth fallback if Firestore API is disabled/unavailable.
    }

    try {
      await for (final snap in _users.doc(user.uid).snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield fallback;
          continue;
        }
        yield MemberProfile.fromMap(user.uid, snap.data()!);
      }
    } catch (_) {
      // Ignore stream errors; fallback already shown.
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }

    // Email is owned by Firebase Auth and cannot be changed here.
    final email = user.email?.trim() ?? '';

    if (user.displayName != fullName.trim()) {
      await user.updateDisplayName(fullName.trim());
      await user.reload();
    }

    try {
      await _users.doc(user.uid).set(
        {
          'fullName': fullName.trim(),
          'email': email,
          'phone': phone.trim(),
        },
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Profile still updated locally via Auth when Firestore is unavailable.
    }
  }

  String _generateMemberId(String uid, DateTime now) {
    final seed = uid.hashCode.abs() ^ now.millisecondsSinceEpoch;
    final number = (seed % 9000) + 1000;
    return 'BJZ-$number';
  }
}
