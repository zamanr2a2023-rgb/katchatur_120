import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/menu/data/app_links_config.dart';
import '../../../../features/menu/data/menu_slider_images.dart';
import '../../../../features/menu/presentation/screens/menu_webview_screen.dart';
import '../../../../services/app_links_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/auto_image_carousel.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/phone_shell.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  bool _opening = false;

  void _openMenuWebView(String url) {
    if (url.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuWebViewScreen(url: url),
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    if (_opening || url.trim().isEmpty) return;
    setState(() => _opening = true);
    try {
      final opened = await AppLinksService.instance.openUrl(url);
      if (!mounted) return;
      if (!opened) {
        _showMessage('Could not open this link.');
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not open this link.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'facebook' => Icons.facebook,
      'instagram' => Icons.camera_alt_outlined,
      'google' => Icons.star_outline_rounded,
      'tripadvisor' => Icons.travel_explore_outlined,
      _ => Icons.link_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(appLinksProvider);

    return PhoneShell(
      nav: BottomNavTab.menu,
      child: linksAsync.when(
        skipLoadingOnReload: true,
        loading: () => _MenuBody(
          config: AppLinksConfig.defaults,
          opening: _opening,
          iconFor: _iconFor,
          onOpenMenu: () =>
              _openMenuWebView(AppLinksConfig.defaults.menuUrl),
          onOpenSocial: (social) => _openExternalLink(social.url),
        ),
        error: (_, _) => _MenuBody(
          config: AppLinksConfig.defaults,
          opening: _opening,
          iconFor: _iconFor,
          onOpenMenu: () =>
              _openMenuWebView(AppLinksConfig.defaults.menuUrl),
          onOpenSocial: (social) => _openExternalLink(social.url),
        ),
        data: (config) => _MenuBody(
          config: config,
          opening: _opening,
          iconFor: _iconFor,
          onOpenMenu: () => _openMenuWebView(config.menuUrl),
          onOpenSocial: (social) => _openExternalLink(social.url),
        ),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({
    required this.config,
    required this.opening,
    required this.iconFor,
    required this.onOpenMenu,
    required this.onOpenSocial,
  });

  final AppLinksConfig config;
  final bool opening;
  final IconData Function(String key) iconFor;
  final VoidCallback onOpenMenu;
  final void Function(AppSocialLink social) onOpenSocial;

  @override
  Widget build(BuildContext context) {
    final socials = config.enabledSocials;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Menu & Socials',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              SizedBox(width: 12),
              BrandLogo(size: LogoSize.sm),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: 'Our menu'),
          const SizedBox(height: 12),
          AppCard(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoImageCarousel(
                  images: MenuSliderImages.images,
                  height: 176,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover Our Menu',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Explore the dishes, flavors and experience waiting for you at Bajatzu.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'View Menu',
                        loading: opening,
                        onPressed: onOpenMenu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Stay Connected'),
          const SizedBox(height: 8),
          const Text(
            'Follow Bajatzu and share your experience.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          ...socials.map(
            (social) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: opening ? null : () => onOpenSocial(social),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconFor(social.icon),
                        size: 20,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            social.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            social.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
