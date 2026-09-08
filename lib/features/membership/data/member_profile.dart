import 'package:cloud_firestore/cloud_firestore.dart';

import 'membership_status.dart';

class MemberProfile {
  const MemberProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.memberId,
    required this.tier,
    required this.createdAt,
    required this.qrPayload,
    this.photoURL,
    this.reviewProofPath,
    this.reviewPlatform,
    this.submittedAt,
    this.resubmissionCount,
    this.rejectionReason,
    this.memberDiscountPercent,
    this.memberBenefit5Percent,
    this.role,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final String memberId;
  final String tier;
  final DateTime createdAt;
  final String qrPayload;
  final String? photoURL;
  final String? reviewProofPath;
  final String? reviewPlatform;
  final DateTime? submittedAt;
  final int? resubmissionCount;
  final String? rejectionReason;
  final int? memberDiscountPercent;
  final bool? memberBenefit5Percent;

  /// Panel-only; read for gating, never written from Flutter.
  final String? role;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Member' : parts.first;
  }

  String get memberSince {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }

  bool get canAccessMemberHome =>
      MembershipStatus.canAccessMemberHome(status);

  bool get canResubmit => MembershipStatus.canResubmit(status);

  /// Panel operators are not normal club members unless productized.
  bool get isPanelOperator => role == 'admin' || role == 'staff';

  /// In-store benefit badge rule (contract §10).
  /// 1) memberDiscountPercent if number
  /// 2) else memberBenefit5Percent == true → 5
  /// 3) else null (no badge)
  int? get displayBenefitPercent {
    final percent = memberDiscountPercent;
    if (percent != null) return percent;
    if (memberBenefit5Percent == true) return 5;
    return null;
  }

  String? get benefitBadgeLabel {
    final percent = displayBenefitPercent;
    if (percent == null) return null;
    return '$percent% Member Benefit';
  }

  factory MemberProfile.fromMap(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    final submittedAt = data['submittedAt'];
    final memberId = (data['memberId'] as String?) ?? 'BJZ-0000';
    final discountRaw = data['memberDiscountPercent'];

    return MemberProfile(
      uid: uid,
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : 'Member',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      status: MembershipStatus.fromFirestore(data['status'] as String?),
      memberId: memberId,
      tier: (data['tier'] as String?) ?? 'Bajatzu Member',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse('$createdAt') ?? DateTime.now(),
      qrPayload: (data['qrPayload'] as String?) ?? 'bajatzu:$memberId:$uid',
      photoURL: data['photoURL'] as String?,
      reviewProofPath: data['reviewProofPath'] as String?,
      reviewPlatform: data['reviewPlatform'] as String?,
      submittedAt: submittedAt is Timestamp ? submittedAt.toDate() : null,
      resubmissionCount: (data['resubmissionCount'] as num?)?.toInt(),
      rejectionReason: (data['rejectionReason'] as String?)?.trim(),
      memberDiscountPercent: discountRaw is num ? discountRaw.toInt() : null,
      memberBenefit5Percent: data['memberBenefit5Percent'] as bool?,
      role: data['role'] as String?,
    );
  }

  /// Fields written on signup create only. Never includes discount / reviewed* / role.
  Map<String, dynamic> toCreateMap({
    required String reviewProofPath,
    required String reviewPlatform,
  }) {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'status': MembershipStatus.pending,
      'memberId': memberId,
      'tier': tier,
      'createdAt': FieldValue.serverTimestamp(),
      'qrPayload': qrPayload,
      'reviewProofPath': reviewProofPath,
      'reviewPlatform': reviewPlatform,
      'submittedAt': FieldValue.serverTimestamp(),
      if (photoURL != null && photoURL!.isNotEmpty) 'photoURL': photoURL,
    };
  }

  MemberProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? status,
    String? memberId,
    String? tier,
    DateTime? createdAt,
    String? qrPayload,
    String? photoURL,
    String? reviewProofPath,
    String? reviewPlatform,
    DateTime? submittedAt,
    int? resubmissionCount,
    String? rejectionReason,
    int? memberDiscountPercent,
    bool? memberBenefit5Percent,
    String? role,
  }) {
    return MemberProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      memberId: memberId ?? this.memberId,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      qrPayload: qrPayload ?? this.qrPayload,
      photoURL: photoURL ?? this.photoURL,
      reviewProofPath: reviewProofPath ?? this.reviewProofPath,
      reviewPlatform: reviewPlatform ?? this.reviewPlatform,
      submittedAt: submittedAt ?? this.submittedAt,
      resubmissionCount: resubmissionCount ?? this.resubmissionCount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      memberDiscountPercent:
          memberDiscountPercent ?? this.memberDiscountPercent,
      memberBenefit5Percent:
          memberBenefit5Percent ?? this.memberBenefit5Percent,
      role: role ?? this.role,
    );
  }
}
