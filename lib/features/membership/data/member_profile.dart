import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory MemberProfile.fromMap(String uid, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return MemberProfile(
      uid: uid,
      fullName: (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? (data['fullName'] as String).trim()
          : 'Member',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'Active',
      memberId: (data['memberId'] as String?) ?? 'BJZ-0000',
      tier: (data['tier'] as String?) ?? 'Bajatzu Member',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse('$createdAt') ?? DateTime.now(),
      qrPayload: (data['qrPayload'] as String?) ??
          (data['memberId'] as String?) ??
          uid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'status': status,
      'memberId': memberId,
      'tier': tier,
      'createdAt': Timestamp.fromDate(createdAt),
      'qrPayload': qrPayload,
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
    );
  }
}
