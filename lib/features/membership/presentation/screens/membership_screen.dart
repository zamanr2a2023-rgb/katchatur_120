import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/mock_data.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/membership_qr_code.dart';
import '../../../../shared/widgets/phone_shell.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key, this.scrollToProfile = false});

  final bool scrollToProfile;

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late String _name = member.fullName;
  late String _email = member.email;
  late String _phone = member.phone;

  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _name);
    _emailCtrl = TextEditingController(text: _email);
    _phoneCtrl = TextEditingController(text: _phone);

    if (widget.scrollToProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _profileKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _name = _nameCtrl.text;
      _email = _emailCtrl.text;
      _phone = _phoneCtrl.text;
      _saving = false;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PhoneShell(
      nav: BottomNavTab.membership,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                const Text(
                  'My Membership',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.tier,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandLogo(size: LogoSize.sm),
                          const Spacer(),
                          AppBadge(
                            label: member.status,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.28),
                            foregroundColor: const Color(0xFFB6E8C8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'MEMBER',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.4,
                          color: AppColors.background.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MEMBER ID',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 2.4,
                                    color: AppColors.background
                                        .withValues(alpha: 0.78),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member.memberId,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1.2,
                                    color: AppColors.background,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'MEMBER SINCE',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2.4,
                                  color: AppColors.background
                                      .withValues(alpha: 0.78),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.memberSince,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'MEMBERSHIP PASS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 248),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: MembershipQrCode(value: member.memberId),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Show this QR code when visiting Bajatzu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                KeyedSubtree(
                  key: _profileKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Account information'),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: _name,
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            _InfoRow(
                              icon: Icons.mail_outline,
                              label: 'Email Address',
                              value: _email,
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: _phone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Edit Profile',
                        variant: AppButtonVariant.secondary,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        onPressed: () {
                          _nameCtrl.text = _name;
                          _emailCtrl.text = _email;
                          _phoneCtrl.text = _phone;
                          setState(() => _editing = true);
                        },
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Log Out',
                        variant: AppButtonVariant.ghost,
                        icon: const Icon(
                          Icons.logout,
                          size: 17,
                          color: AppColors.mutedForeground,
                        ),
                        onPressed: () => context.goNamed(RouteNames.login),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_editing)
            _EditProfileSheet(
              nameCtrl: _nameCtrl,
              emailCtrl: _emailCtrl,
              phoneCtrl: _phoneCtrl,
              saving: _saving,
              onSave: _save,
              onCancel: () {
                if (!_saving) setState(() => _editing = false);
              },
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatelessWidget {
  const _EditProfileSheet({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: AppColors.ink.withValues(alpha: 0.4),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + keyboardInset),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Update the details linked to your membership.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(label: 'Full Name', controller: nameCtrl),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email Address',
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Phone Number',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Save Changes',
                      loading: saving,
                      onPressed: onSave,
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: saving ? null : onCancel,
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
