import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads membership review proofs to Storage.
/// Stores only the path on Firestore (`reviewProofPath`), never a download URL.
class MembershipProofStorage {
  MembershipProofStorage._();

  static final MembershipProofStorage instance = MembershipProofStorage._();

  static const int maxBytes = 5 * 1024 * 1024; // 5 MiB
  static const Set<String> allowedExts = {'jpg', 'jpeg', 'png', 'webp'};

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickProofImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  /// Uploads [file] to `membership_proofs/{uid}/{timestampMs}.{ext}`.
  /// Returns the Storage **path** (not a download URL).
  Future<String> uploadProof({
    required String uid,
    required XFile file,
  }) async {
    final ext = _normalizeExt(file.name, file.mimeType);
    if (!allowedExts.contains(ext)) {
      throw StateError(
        'Unsupported image type. Use jpg, jpeg, png, or webp.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw StateError('Image must be 5 MB or smaller.');
    }

    final contentType = file.mimeType?.startsWith('image/') == true
        ? file.mimeType!
        : 'image/$ext';

    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final path = 'membership_proofs/$uid/$timestampMs.$ext';
    final ref = _storage.ref(path);

    final metadata = SettableMetadata(contentType: contentType);

    if (kIsWeb) {
      await ref.putData(Uint8List.fromList(bytes), metadata);
    } else {
      await ref.putFile(File(file.path), metadata);
    }

    // Contract: store path only — never getDownloadURL().
    return path;
  }

  String _normalizeExt(String fileName, String? mimeType) {
    final fromName = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (allowedExts.contains(fromName)) {
      return fromName == 'jpeg' ? 'jpg' : fromName;
    }

    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return fromName.isEmpty ? 'jpg' : fromName;
    }
  }
}
