import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/membership/data/visit_record.dart';

/// Listens for successful door visits and exposes one-shot welcome events.
///
/// Flutter never writes to `visits`. See FLUTTER_CONTRACT_DOOR_WELCOME.md.
class VisitWelcomeService {
  VisitWelcomeService._();

  static final VisitWelcomeService instance = VisitWelcomeService._();

  static const freshnessWindow = Duration(seconds: 30);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Future<void>? _handling;

  /// Latest visit the UI should show (null when idle / dismissed).
  final ValueNotifier<VisitRecord?> pendingWelcome =
      ValueNotifier<VisitRecord?>(null);

  bool _catchUpDone = false;
  String? _listeningUid;
  String? _shownOrPendingId;
  String? _prefsCachedId;
  bool _listenerFailed = false;

  bool get listenerFailed => _listenerFailed;
  String? get listeningUid => _listeningUid;

  String _prefsKeyFor(String uid) => 'lastShownVisitId:$uid';

  /// Starts (or restarts) the listener for [uid] while the member is Active.
  void start({required String uid}) {
    if (_listeningUid == uid &&
        _subscription != null &&
        !_listenerFailed) {
      return;
    }

    stop(clearPending: false);
    _listeningUid = uid;
    _catchUpDone = false;
    _shownOrPendingId = null;
    _prefsCachedId = null;
    _listenerFailed = false;

    debugPrint('VisitWelcomeService: start uid=$uid');

    _subscription = _db
        .collection('visits')
        .where('uid', isEqualTo: uid)
        .where('result', isEqualTo: 'success')
        .orderBy('scannedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            _handling = (_handling ?? Future<void>.value())
                .then((_) => _onSnapshot(snapshot))
                .catchError((Object e, StackTrace st) {
              debugPrint('VisitWelcomeService snapshot handler error: $e');
              if (kDebugMode) debugPrint('$st');
            });
          },
          onError: (Object error, StackTrace stack) {
            _listenerFailed = true;
            final text = error.toString().toLowerCase();
            if (text.contains('permission-denied') ||
                (error is FirebaseException &&
                    error.code == 'permission-denied')) {
              debugPrint(
                'VisitWelcomeService: permission-denied on visits '
                '(need member self-read rules). $error',
              );
            } else if (text.contains('failed-precondition') ||
                (error is FirebaseException &&
                    error.code == 'failed-precondition')) {
              debugPrint(
                'VisitWelcomeService: failed-precondition '
                '(need visits uid+result+scannedAt index). $error',
              );
            } else {
              debugPrint('VisitWelcomeService listener error: $error');
              if (kDebugMode) debugPrint('$stack');
            }
          },
        );
  }

  /// Stops the Firestore listener. Pending overlay is kept unless [clearPending].
  void stop({bool clearPending = true}) {
    _subscription?.cancel();
    _subscription = null;
    _listeningUid = null;
    _catchUpDone = false;
    _listenerFailed = false;
    if (clearPending) {
      _shownOrPendingId = null;
      pendingWelcome.value = null;
    }
  }

  void disposeForSignOut() {
    stop(clearPending: true);
    _prefsCachedId = null;
  }

  /// Call after the overlay is actually presented (or dismissed after show).
  Future<void> markShown(VisitRecord visit) async {
    final uid = visit.uid;
    if (uid.isEmpty) return;
    _shownOrPendingId = visit.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyFor(uid), visit.id);
    _prefsCachedId = visit.id;
    debugPrint('VisitWelcomeService: marked shown ${visit.id}');
  }

  void clearPending() {
    pendingWelcome.value = null;
  }

  Future<void> _onSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (snapshot.docs.isEmpty) {
      _catchUpDone = true;
      debugPrint('VisitWelcomeService: empty snapshot (catch-up done)');
      return;
    }

    final visit = VisitRecord.fromDoc(snapshot.docs.first);
    debugPrint(
      'VisitWelcomeService: snapshot id=${visit.id} result=${visit.result} '
      'scannedAt=${visit.scannedAt?.toIso8601String()} '
      'catchUpDone=$_catchUpDone',
    );

    // Server timestamp still pending — wait for the next emission.
    if (visit.scannedAt == null) {
      debugPrint('VisitWelcomeService: scannedAt null — wait');
      return;
    }

    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid != visit.uid) {
      debugPrint('VisitWelcomeService: uid mismatch — skip');
      return;
    }

    if (!visit.isSuccess) return;

    final lastShown = await _lastShownId(currentUid);
    final age = DateTime.now().difference(visit.scannedAt!);
    // Allow a few seconds of clock skew ahead of device time.
    final isFresh =
        age <= freshnessWindow && age >= const Duration(seconds: -10);
    final isNewId =
        visit.id != lastShown && visit.id != _shownOrPendingId;

    if (!_catchUpDone) {
      _catchUpDone = true;
      // First emission is catch-up unless the visit is very recent.
      if (!isFresh || !isNewId) {
        debugPrint(
          'VisitWelcomeService: catch-up skip fresh=$isFresh new=$isNewId age=${age.inSeconds}s',
        );
        return;
      }
    } else if (!isFresh || !isNewId) {
      debugPrint(
        'VisitWelcomeService: skip fresh=$isFresh new=$isNewId age=${age.inSeconds}s',
      );
      return;
    }

    _shownOrPendingId = visit.id;
    pendingWelcome.value = visit;
    debugPrint('VisitWelcomeService: pending welcome ${visit.id}');
  }

  Future<String?> _lastShownId(String uid) async {
    if (_prefsCachedId != null) return _prefsCachedId;
    final prefs = await SharedPreferences.getInstance();
    _prefsCachedId = prefs.getString(_prefsKeyFor(uid));
    return _prefsCachedId;
  }
}
