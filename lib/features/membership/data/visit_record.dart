import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-written door scan log. Flutter never creates/updates/deletes these.
class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.uid,
    required this.fullName,
    required this.memberId,
    required this.scannedAt,
    required this.verifiedByAdminId,
    required this.result,
    required this.qrPayload,
  });

  final String id;
  final String uid;
  final String fullName;
  final String memberId;
  final DateTime? scannedAt;
  final String verifiedByAdminId;
  final String result;
  final String qrPayload;

  bool get isSuccess => result == 'success';

  String get welcomeTitle {
    final name = fullName.trim();
    if (name.isEmpty) return 'Welcome';
    return 'Welcome, $name';
  }

  factory VisitRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final scannedAt = data['scannedAt'];
    return VisitRecord(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      fullName: (data['fullName'] as String?)?.trim() ?? '',
      memberId: (data['memberId'] as String?) ?? '',
      scannedAt: scannedAt is Timestamp ? scannedAt.toDate() : null,
      verifiedByAdminId: (data['verifiedByAdminId'] as String?) ?? '',
      result: (data['result'] as String?) ?? '',
      qrPayload: (data['qrPayload'] as String?) ?? '',
    );
  }
}
