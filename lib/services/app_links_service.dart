import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/menu/data/app_links_config.dart';

class AppLinksService {
  AppLinksService._();

  static final AppLinksService instance = AppLinksService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('app_config').doc('links');

  /// Always emits defaults first so the UI never stays stuck loading.
  Stream<AppLinksConfig> watchLinks() async* {
    yield AppLinksConfig.defaults;

    try {
      final remote = await _fetchRemote()
          .timeout(const Duration(seconds: 6));
      if (remote != null) {
        yield remote;
      }
    } catch (_) {
      // Keep showing defaults if Firestore is slow/unavailable.
    }

    try {
      await for (final snap in _doc.snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield AppLinksConfig.defaults;
          continue;
        }
        yield AppLinksConfig.fromMap(snap.data()!);
      }
    } catch (_) {
      // Ignore snapshot channel errors; defaults already shown.
    }
  }

  Future<AppLinksConfig?> _fetchRemote() async {
    try {
      await ensureDefaults();
      final snap = await _doc.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (!snap.exists || snap.data() == null) {
        return AppLinksConfig.defaults;
      }
      return AppLinksConfig.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<AppLinksConfig> getLinks() async {
    try {
      final remote = await _fetchRemote()
          .timeout(const Duration(seconds: 6));
      return remote ?? AppLinksConfig.defaults;
    } catch (_) {
      return AppLinksConfig.defaults;
    }
  }

  /// Seeds Firestore with default Bajatzu links if missing.
  Future<void> ensureDefaults() async {
    final snap = await _doc.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snap.exists && snap.data() != null) return;
    await _doc.set(AppLinksConfig.defaults.toMap());
  }

  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
