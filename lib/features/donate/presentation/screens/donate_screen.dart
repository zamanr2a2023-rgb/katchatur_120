import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock_data.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/phone_shell.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int? _amount = 20;
  String _custom = '';
  bool _processing = false;
  bool _done = false;
  final _customCtrl = TextEditingController();

  num? get _finalAmount {
    if (_custom.isNotEmpty) return num.tryParse(_custom);
    return _amount;
  }

  bool get _canDonate =>
      _finalAmount != null && _finalAmount! > 0;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Support Our Chef',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you enjoyed your experience at Bajatzu, you can show your appreciation with a donation.',
                  style: TextStyle(
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
                  itemCount: donationPresets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (context, index) {
                    final value = donationPresets[index];
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
                            '€$value',
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
                      const Text(
                        '€',
                        style: TextStyle(
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
                      const Row(
                        children: [
                          _PayIcon(),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure payment with SumUp',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  'Card details are handled by SumUp, never by Bajatzu.',
                                  style: TextStyle(
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
                              '€${_canDonate ? _finalAmount : 0}',
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
                      ? 'Contacting SumUp'
                      : 'Donate with SumUp',
                  loading: _processing,
                  onPressed: _canDonate ? _pay : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Simulated payment · no charge is made in this prototype',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (_done)
            _ThankYouOverlay(
              amount: _finalAmount ?? 0,
              onHome: () => context.goNamed(RouteNames.home),
              onDone: () => setState(() => _done = false),
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

class _ThankYouOverlay extends StatelessWidget {
  const _ThankYouOverlay({
    required this.amount,
    required this.onHome,
    required this.onDone,
  });

  final num amount;
  final VoidCallback onHome;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                        '€$amount',
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
                AppButton(label: 'Back to Home', onPressed: onHome),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.ghost,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
