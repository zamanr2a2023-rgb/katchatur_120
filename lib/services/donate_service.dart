import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../features/donate/data/donate_config.dart';

class StripeCheckoutSession {
  const StripeCheckoutSession({
    required this.sessionId,
    required this.url,
  });

  final String sessionId;
  final String url;
}

class DonateService {
  DonateService._();

  static final DonateService instance = DonateService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const region = 'europe-west1';

  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: region,
      );

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _db.collection('app_config').doc('donate');

  Stream<DonateConfig> watchConfig() async* {
    yield DonateConfig.defaults;

    try {
      final remote = await _fetchConfig().timeout(const Duration(seconds: 6));
      if (remote != null) yield remote;
    } catch (_) {}

    try {
      await for (final snap in _configDoc.snapshots()) {
        if (!snap.exists || snap.data() == null) {
          yield DonateConfig.defaults;
          continue;
        }
        yield DonateConfig.fromMap(snap.data()!);
      }
    } catch (_) {}
  }

  Future<DonateConfig?> _fetchConfig() async {
    try {
      await ensureDefaults();
      final snap = await _configDoc.get(
        const GetOptions(source: Source.serverAndCache),
      );
      if (!snap.exists || snap.data() == null) return DonateConfig.defaults;
      return DonateConfig.fromMap(snap.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> ensureDefaults() async {
    final snap = await _configDoc.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snap.exists && snap.data() != null) return;
    await _configDoc.set(DonateConfig.defaults.toMap());
  }

  Future<StripeCheckoutSession> createCheckoutSession({
    required num amount,
    required String currency,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to donate.');
    }

    await user.getIdToken(true);

    final callable = _functions.httpsCallable(
      'createCheckoutSession',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 25),
      ),
    );
    final result = await callable.call(<String, dynamic>{
      'amount': amount,
      'currency': _toStripeCurrency(currency),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = '${data['url'] ?? ''}';
    final sessionId = '${data['sessionId'] ?? ''}';
    if (url.isEmpty || sessionId.isEmpty) {
      throw StateError('Could not start Stripe checkout.');
    }
    return StripeCheckoutSession(sessionId: sessionId, url: url);
  }

  static String _toStripeCurrency(String symbol) {
    final value = symbol.trim().toLowerCase();
    if (value == '€' || value == 'eur') return 'eur';
    if (value == r'$' || value == 'usd') return 'usd';
    if (value == '£' || value == 'gbp') return 'gbp';
    if (RegExp(r'^[a-z]{3}$').hasMatch(value)) return value;
    return 'eur';
  }

  Future<bool> confirmDonation(String sessionId) async {
    final callable = _functions.httpsCallable(
      'confirmDonation',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 20),
      ),
    );
    final result = await callable.call(<String, dynamic>{
      'sessionId': sessionId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['paid'] == true;
  }

  static String mapPaymentError(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'Please sign in to donate.';
        case 'invalid-argument':
          return error.message ?? 'Enter a valid donation amount.';
        case 'failed-precondition':
          return error.message?.trim().isNotEmpty == true
              ? error.message!
              : 'Stripe is not configured yet. Add your Stripe secret key in Firebase.';
        case 'not-found':
          return 'Payment is not ready yet. Deploy Stripe Cloud Functions first.';
        case 'internal':
        case 'unavailable':
        case 'deadline-exceeded':
          final raw = (error.message ?? '').trim();
          if (raw.isEmpty || raw.toUpperCase() == 'INTERNAL') {
            return 'Could not start payment. Please try again.';
          }
          if (raw.toLowerCase().contains('timeout') ||
              raw.toLowerCase().contains('deadline')) {
            return 'Payment service is taking too long. Please try again.';
          }
          return raw;
        default:
          final fallback = (error.message ?? '').trim();
          if (fallback.isEmpty || fallback.toUpperCase() == 'INTERNAL') {
            return 'Could not start payment. Please try again.';
          }
          return fallback;
      }
    }
    final message = error.toString().toLowerCase();
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Payment service is taking too long. Please try again.';
    }
    if (message.contains('not found') || message.contains('not-found')) {
      return 'Payment is not ready yet. Deploy Stripe Cloud Functions first.';
    }
    if (message.contains('unauthenticated')) {
      return 'Please sign in to donate.';
    }
    return 'Could not start payment. Please try again.';
  }
}
