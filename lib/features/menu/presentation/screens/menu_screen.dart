import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/phone_shell.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return PhoneShell(
      nav: BottomNavTab.home,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                const Row(
                  children: [
                    Text(
                      'Bajatzu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Spacer(),
                    BajatzuLogo(size: LogoSize.sm),
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
                      Image.asset(
                        'assets/images/dish.jpg',
                        height: 176,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
                              onPressed: () =>
                                  setState(() => _menuOpen = true),
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
          if (_menuOpen)
            _MenuPreview(onClose: () => setState(() => _menuOpen = false)),
        ],
      ),
    );
  }
}

class _MenuPreview extends StatelessWidget {
  const _MenuPreview({required this.onClose});

  final VoidCallback onClose;

  static const items = [
    ['Chef\'s Tasting Menu', '5 courses · €58'],
    ['Slow-cooked Lamb', '€26'],
    ['Seared Sea Bass', '€24'],
    ['Chocolate & Olive Oil', '€9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Menu Preview',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "The full Bajatzu menu will open here. In the final app this links to the restaurant's live menu.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item[0],
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              item[1],
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Close',
                      variant: AppButtonVariant.secondary,
                      onPressed: onClose,
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: AppColors.muted,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClose,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
