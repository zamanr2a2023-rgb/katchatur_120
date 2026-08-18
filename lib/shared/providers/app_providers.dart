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

final appLinksProvider = StreamProvider<AppLinksConfig>((ref) {
  return AppLinksService.instance.watchLinks();
});

final donateConfigProvider = StreamProvider<DonateConfig>((ref) {
  return DonateService.instance.watchConfig();
});
