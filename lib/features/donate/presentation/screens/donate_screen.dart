import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/donate/data/donate_config.dart';
import '../../../../features/donate/presentation/screens/stripe_checkout_screen.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/donate_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/phone_shell.dart';

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key, this.scrollToBenefit = false});

  final bool scrollToBenefit;

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  int? _amount = DonateConfig.defaults.defaultAmount;
  String _custom = '';
  bool _processing = false;
  bool _done = false;
  bool _claimOpen = false;
  final _customCtrl = TextEditingController();
  final _benefitKey = GlobalKey();

  num? get _finalAmount {
    if (_custom.isNotEmpty) return num.tryParse(_custom);
    return _amount;
  }

  bool get _canDonate => _finalAmount != null && _finalAmount! > 0;

  @override
  void initState() {
    super.initState();
    if (widget.scrollToBenefit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _benefitKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.15,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay(DonateConfig config) async {
    if (!_canDonate) return;
    setState(() => _processing = true);

    try {
      final session = await DonateService.instance.createCheckoutSession(
        amount: _finalAmount!,
        currency: config.currency,
      );
      if (!mounted) return;
      setState(() => _processing = false);

      final result = await Navigator.of(context).push<(String, String)?>(
        MaterialPageRoute(
          builder: (_) => StripeCheckoutScreen(checkoutUrl: session.url),
        ),
      );
      if (!mounted || result == null || result.$1 != 'success') return;

      FocusScope.of(context).unfocus();
      setState(() {
        _processing = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showMessage(DonateService.mapPaymentError(e));
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

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(donateConfigProvider);
    final config = configAsync.asData?.value ?? DonateConfig.defaults;

    return PhoneShell(
      nav: BottomNavTab.donate,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/chef.jpg',
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.ink.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 16,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: AppColors.primaryForeground,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  config.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle(title: 'Choose an amount'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: config.presets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (context, index) {
                    final value = config.presets[index];
                    final selected = _custom.isEmpty && _amount == value;
                    return Material(
                      color: selected
                          ? AppColors.primarySoft
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => setState(() {
                          _amount = value;
                          _custom = '';
                          _customCtrl.clear();
                        }),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${config.currency}$value',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Custom Amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _custom.isNotEmpty
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    boxShadow: _custom.isNotEmpty
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 0,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        config.currency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter amount',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          style: const TextStyle(fontSize: 15),
                          controller: _customCtrl,
                          onChanged: (v) {
                            final cleaned =
                                v.replaceAll(RegExp(r'[^\d.]'), '');
                            if (cleaned != v) {
                              _customCtrl.value = TextEditingValue(
                                text: cleaned,
                                selection: TextSelection.collapsed(
                                  offset: cleaned.length,
                                ),
                              );
                            }
                            setState(() => _custom = cleaned);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle(title: 'Payment'),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const _PayIcon(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure payment with ${config.paymentProvider}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  config.paymentSubtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${config.currency}${_canDonate ? _finalAmount : 0}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _processing
                      ? 'Contacting ${config.paymentProvider}'
                      : 'Donate with ${config.paymentProvider}',
                  loading: _processing,
                  onPressed: _canDonate ? () => _pay(config) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  config.paymentDisclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 32),
                KeyedSubtree(
                  key: _benefitKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Member Benefit'),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.percent_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        config.memberBenefitTitle,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        config.memberBenefitDescription,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.mutedForeground,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'MEMBERS ONLY',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.accentForeground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Claim Member Discount',
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  setState(() => _claimOpen = true),
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
          if (_claimOpen)
            Positioned.fill(
              child: _MemberDiscountSheet(
                percent: config.memberBenefitPercent,
                onClose: () => setState(() => _claimOpen = false),
                onViewQr: () {
                  setState(() => _claimOpen = false);
                  context.goNamed(RouteNames.membership);
                },
              ),
            ),
          if (_done)
            Positioned.fill(
              child: _ThankYouOverlay(
                amount: _finalAmount ?? 0,
                currency: config.currency,
                onHome: () => context.goNamed(RouteNames.home),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayIcon extends StatelessWidget {
  const _PayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        size: 19,
        color: AppColors.primary,
      ),
    );
  }
}

class _MemberDiscountSheet extends StatelessWidget {
  const _MemberDiscountSheet({
    required this.percent,
    required this.onClose,
    required this.onViewQr,
  });

  final int percent;
  final VoidCallback onClose;
  final VoidCallback onViewQr;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.4),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your $percent% Member Discount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Show your active Bajatzu membership QR code to the restaurant staff to receive your member discount.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'View Membership QR',
                    onPressed: onViewQr,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.secondary,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThankYouOverlay extends StatefulWidget {
  const _ThankYouOverlay({
    required this.amount,
    required this.currency,
    required this.onHome,
  });

  final num amount;
  final String currency;
  final VoidCallback onHome;

  @override
  State<_ThankYouOverlay> createState() => _ThankYouOverlayState();
}

class _ThankYouOverlayState extends State<_ThankYouOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.45),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 36,
                              color: AppColors.primaryForeground,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Thank You!',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thank you for supporting the chef and the Bajatzu team.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Donation Amount',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${widget.currency}${widget.amount}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Back to Home',
                            onPressed: widget.onHome,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your Stripe payment was received. Thank you for supporting the chef.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
