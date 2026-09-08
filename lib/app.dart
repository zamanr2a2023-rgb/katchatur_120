import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'shared/providers/app_providers.dart';

class BajatzuApp extends ConsumerStatefulWidget {
  const BajatzuApp({super.key});

  @override
  ConsumerState<BajatzuApp> createState() => _BajatzuAppState();
}

class _BajatzuAppState extends ConsumerState<BajatzuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.instance.startSessionGuard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Kick / Auth disable: force re-auth when the refreshed token fails.
      // Firestore status is still re-checked via membership snapshots.
      AuthService.instance.verifySessionOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep visits listener alive for Active members (door welcome).
    ref.watch(visitWelcomeBindingProvider);

    final router = ref.watch(appRouterProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: MaterialApp.router(
        title: 'Bajatzu — Restaurant Membership',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
