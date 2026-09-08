import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../features/donate/data/donate_config.dart';
import '../../features/membership/data/member_profile.dart';
import '../../features/menu/data/app_links_config.dart';
import '../../services/app_links_service.dart';
import '../../services/auth_service.dart';
import '../../services/donate_service.dart';
import '../../services/membership_service.dart';
import '../../services/visit_welcome_service.dart';

/// Example provider — add feature providers under each feature folder.
final appNameProvider = Provider<String>((ref) {
  return AppConstants.appName;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

final currentMembershipProvider = StreamProvider<MemberProfile?>((ref) {
  ref.watch(authStateProvider);
  if (!AuthService.instance.isSignedIn) {
    return Stream.value(null);
  }
  return MembershipService.instance.watchCurrentMembership();
});

/// Keeps the door-welcome visits listener alive while signed-in + Active.
/// Does not depend on MembershipScreen being mounted.
final visitWelcomeBindingProvider = Provider<void>((ref) {
  void sync(MemberProfile? profile) {
    final uid = AuthService.instance.currentUser?.uid;
    if (profile != null && profile.canAccessMemberHome && uid != null) {
      VisitWelcomeService.instance.start(uid: uid);
    } else {
      VisitWelcomeService.instance.stop(clearPending: true);
    }
  }

  // fireImmediately so we bind on first read without watching (avoids
  // restarting the visits listener on every membership snapshot).
  ref.listen<AsyncValue<MemberProfile?>>(
    currentMembershipProvider,
    (_, next) {
      if (!AuthService.instance.isSignedIn) {
        VisitWelcomeService.instance.disposeForSignOut();
        return;
      }
      next.when(
        data: sync,
        loading: () {},
        error: (_, _) => VisitWelcomeService.instance.stop(clearPending: true),
      );
    },
    fireImmediately: true,
  );

  ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
    if (next.asData?.value == null) {
      VisitWelcomeService.instance.disposeForSignOut();
    }
  });

  ref.onDispose(() {
    VisitWelcomeService.instance.stop(clearPending: false);
  });
});

final appLinksProvider = StreamProvider<AppLinksConfig>((ref) {
  return AppLinksService.instance.watchLinks();
});

final donateConfigProvider = StreamProvider<DonateConfig>((ref) {
  return DonateService.instance.watchConfig();
});
