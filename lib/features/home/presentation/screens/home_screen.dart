import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/donate/data/donate_config.dart';
import '../../../../features/menu/data/menu_slider_images.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/auto_image_carousel.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/phone_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(authStateProvider).asData?.value != null ||
        AuthService.instance.isSignedIn;
    final membership = isSignedIn
        ? ref.watch(currentMembershipProvider).asData?.value
        : null;
    final donateConfig =
        ref.watch(donateConfigProvider).asData?.value ?? DonateConfig.defaults;
    final firstName = isSignedIn ? (membership?.firstName ?? 'Member') : 'Guest';
    final status = membership?.status ?? 'Active';
    final memberId = membership?.memberId ?? '—';
    final benefitLabel =
        '${donateConfig.memberBenefitPercent}% Member Benefit';

    return PhoneShell(
      nav: BottomNavTab.home,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const LogoMark(size: 40, fontSize: 17),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          isSignedIn
                              ? 'Good to see you again.'
                              : 'Browse the menu without an account.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.card,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.go(
                        isSignedIn
                            ? RoutePaths.membership
                            : '${RoutePaths.login}?redirect=${Uri.encodeComponent(RoutePaths.membership)}',
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _HomeBannerCarousel(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Quick access'),
                  const SizedBox(height: 12),
                  if (isSignedIn)
                    AppCard(
                      onTap: () => context.goNamed(RouteNames.membership),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: AppColors.background,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    const Text(
                                      'My Membership',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    AppBadge(label: status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$memberId · View Membership',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.go(
                                    '${RoutePaths.donate}?section=benefit',
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      benefitLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.mutedForeground,
                          ),
                        ],
                      ),
                    )
                  else
                    AppCard(
                      onTap: () => context.go(
                        '${RoutePaths.login}?redirect=${Uri.encodeComponent(RoutePaths.membership)}',
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: AppColors.background,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Membership',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sign in to view your membership QR.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  AppCard(
                    onTap: () => context.goNamed(RouteNames.menu),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        AutoImageCarousel(
                          images: MenuSliderImages.images,
                          height: 180,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant_outlined,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Our Menu',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      'Explore Menu',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.mutedForeground,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AppCard(
                            expand: true,
                            onTap: () => context.goNamed(RouteNames.donate),
                            color: AppColors.ink,
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _IconBox(
                                  color: AppColors.primary,
                                  icon: Icons.volunteer_activism,
                                  iconColor: AppColors.primaryForeground,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Donate to the chef',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.background,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Make a Donation',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xB3F6F5F2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            expand: true,
                            onTap: () => context.goNamed(RouteNames.menu),
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _IconBox(
                                  color: AppColors.secondary,
                                  icon: Icons.share_outlined,
                                  iconColor: AppColors.foreground,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stay Connected',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Follow Bajatzu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel();

  static const _images = [
    'assets/images/home_interior_1.png',
    'assets/images/home_interior_2.png',
    'assets/images/home_interior_3.png',
    'assets/images/home_interior_4.png',
  ];

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  static const _autoInterval = Duration(seconds: 8);

  int _index = 0;
  late final PageController _pageController;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final count = _HomeBannerCarousel._images.length;
      final next = (_index + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 224,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.ink),
            PageView.builder(
              controller: _pageController,
              itemCount: _HomeBannerCarousel._images.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) {
                return Image.asset(
                  _HomeBannerCarousel._images[i],
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.ink.withValues(alpha: 0.25),
                    AppColors.ink.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Bajatzu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A table, a story and a chef who cooks for you personally. Thank you for being part of our house.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.background.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      _HomeBannerCarousel._images.length,
                      (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(
                              alpha: active ? 1 : 0.45,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: BrandLogo(size: LogoSize.sm),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}
