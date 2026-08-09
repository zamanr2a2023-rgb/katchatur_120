import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.goNamed(RouteNames.login);
      }
    });
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BajatzuLogo(size: LogoSize.lg),
                const SizedBox(height: 40),
                SizedBox(
                  width: 96,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 3,
                          backgroundColor: AppColors.muted,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36 + bottom,
            child: Text(
              'MEMBERS CLUB',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.4,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
