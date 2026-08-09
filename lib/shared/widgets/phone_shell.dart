import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/route_names.dart';

enum BottomNavTab { home, membership, donate, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.active});

  final BottomNavTab active;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        tab: BottomNavTab.home,
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        path: RoutePaths.home,
      ),
      (
        tab: BottomNavTab.membership,
        label: 'Membership',
        icon: Icons.qr_code_2_outlined,
        activeIcon: Icons.qr_code_2,
        path: RoutePaths.membership,
      ),
      (
        tab: BottomNavTab.donate,
        label: 'Donate',
        icon: Icons.volunteer_activism_outlined,
        activeIcon: Icons.volunteer_activism,
        path: RoutePaths.donate,
      ),
      (
        tab: BottomNavTab.profile,
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        path: '${RoutePaths.membership}?section=profile',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: items.map((item) {
              final isActive = item.tab == active;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.path),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 48,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 19,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class PhoneShell extends StatelessWidget {
  const PhoneShell({
    super.key,
    required this.child,
    this.nav,
  });

  final Widget child;
  final BottomNavTab? nav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(child: child),
          if (nav != null) AppBottomNav(active: nav!),
        ],
      ),
    );
  }
}
