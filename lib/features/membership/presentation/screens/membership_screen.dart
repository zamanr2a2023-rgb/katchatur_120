import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/membership/data/member_profile.dart';
import '../../../../features/membership/data/visit_record.dart';
import '../../../../features/membership/presentation/screens/membership_status_screen.dart';
import '../../../../features/membership/presentation/widgets/door_welcome_overlay.dart';
import '../../../../routes/route_names.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/membership_service.dart';
import '../../../../services/visit_welcome_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/logo.dart';
import '../../../../shared/widgets/membership_qr_code.dart';
import '../../../../shared/widgets/phone_shell.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key, this.scrollToProfile = false});

  final bool scrollToProfile;

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _editing = false;
  bool _saving = false;
  String? _saveError;
  String? _markedWelcomeId;
  VisitRecord? _welcomeVisit;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    VisitWelcomeService.instance.pendingWelcome.addListener(_onPendingWelcome);
    final pending = VisitWelcomeService.instance.pendingWelcome.value;
    _welcomeVisit =
        (pending != null && _isFreshEnough(pending)) ? pending : null;
    if (pending != null && _welcomeVisit == null) {
      VisitWelcomeService.instance.clearPending();
    }

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

  void _onPendingWelcome() {
    if (!mounted) return;
    final visit = VisitWelcomeService.instance.pendingWelcome.value;
    if (visit != null && !_isFreshEnough(visit)) {
      VisitWelcomeService.instance.clearPending();
      setState(() => _welcomeVisit = null);
      return;
    }
    setState(() => _welcomeVisit = visit);
  }

  bool _isFreshEnough(VisitRecord visit) {
    final scannedAt = visit.scannedAt;
    if (scannedAt == null) return false;
    final age = DateTime.now().difference(scannedAt);
    return age <= VisitWelcomeService.freshnessWindow &&
        age >= const Duration(seconds: -10);
  }

  @override
  void dispose() {
    VisitWelcomeService.instance.pendingWelcome.removeListener(_onPendingWelcome);
    // Visit listener is owned by visitWelcomeBindingProvider (app-level).
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _onWelcomePresented(VisitRecord visit) async {
    if (_markedWelcomeId == visit.id) return;
    _markedWelcomeId = visit.id;
    await VisitWelcomeService.instance.markShown(visit);
  }

  void _onWelcomeDismissed() {
    VisitWelcomeService.instance.clearPending();
  }

  Future<void> _save() async {
    if (!AuthService.instance.isSignedIn) {
      if (!mounted) return;
      context.go(
        '${RoutePaths.login}?redirect=${Uri.encodeComponent(RoutePaths.membership)}',
      );
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await MembershipService.instance.updateProfile(
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
      );
      if (!mounted) return;
      ref.invalidate(currentMembershipProvider);
      setState(() {
        _saving = false;
        _editing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save profile. Please try again.';
      });
    }
  }

  void _startEditing(MemberProfile profile) {
    final authEmail = AuthService.instance.currentUser?.email;
    _nameCtrl.text = profile.fullName;
    _emailCtrl.text =
        (authEmail?.trim().isNotEmpty == true) ? authEmail!.trim() : profile.email;
    _phoneCtrl.text = profile.phone;
    setState(() {
      _editing = true;
      _saveError = null;
    });
  }

  MemberProfile _withAuthEmail(MemberProfile profile) {
    final authEmail = AuthService.instance.currentUser?.email?.trim();
    if (authEmail == null || authEmail.isEmpty || authEmail == profile.email) {
      return profile;
    }
    return profile.copyWith(email: authEmail);
  }

  Widget _bodyForProfile(MemberProfile profile) {
    return _MembershipBody(
      profile: profile,
      profileKey: _profileKey,
      editing: _editing,
      saving: _saving,
      saveError: _saveError,
      nameCtrl: _nameCtrl,
      emailCtrl: _emailCtrl,
      phoneCtrl: _phoneCtrl,
      onEdit: () => _startEditing(profile),
      onSave: _save,
      onCancelEdit: () {
        if (!_saving) {
          setState(() {
            _editing = false;
            _saveError = null;
          });
        }
      },
      onLogout: () async {
        await AuthService.instance.signOut();
        if (!mounted) return;
        context.goNamed(RouteNames.home);
      },
    );
  }

  Widget _missingProfile() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text(
              'Membership profile not found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account is signed in, but no membership document exists. Please contact support or register again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, height: 1.45),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Log Out',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                await AuthService.instance.signOut();
                if (!mounted) return;
                context.goNamed(RouteNames.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membershipAsync = ref.watch(currentMembershipProvider);
    final isSignedIn = AuthService.instance.isSignedIn;
    final welcome = _welcomeVisit;

    if (welcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onWelcomePresented(welcome);
      });
    }

    Widget guestSignIn() {
      return _ErrorState(
        message: 'Please sign in to view your membership.',
        onRetry: () => context.go(
          '${RoutePaths.login}?redirect=${Uri.encodeComponent(RoutePaths.membership)}',
        ),
        retryLabel: 'Sign In',
      );
    }

    final shell = PhoneShell(
      nav: BottomNavTab.membership,
      child: !isSignedIn
          ? guestSignIn()
          : membershipAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => _ErrorState(
                message:
                    'Could not load membership. Please try again.\n$error',
                onRetry: () => ref.invalidate(currentMembershipProvider),
              ),
              data: (profile) {
                if (profile == null) return _missingProfile();
                final liveProfile = _withAuthEmail(profile);

                if (!liveProfile.canAccessMemberHome) {
                  return MembershipStatusScreen(
                    profile: liveProfile,
                    onSignedOut: () async {
                      await AuthService.instance.signOut();
                      if (!context.mounted) return;
                      context.goNamed(RouteNames.home);
                    },
                  );
                }

                return _bodyForProfile(liveProfile);
              },
            ),
    );

    // Full-screen over shell (covers bottom nav) on the QR / membership screen.
    return Stack(
      children: [
        shell,
        if (welcome != null &&
            isSignedIn &&
            (membershipAsync.asData?.value?.canAccessMemberHome ?? false))
          Positioned.fill(
            child: DoorWelcomeOverlay(
              key: ValueKey(welcome.id),
              visit: welcome,
              onDismissed: _onWelcomeDismissed,
            ),
          ),
      ],
    );
  }
}

class _MembershipBody extends StatelessWidget {
  const _MembershipBody({
    required this.profile,
    required this.profileKey,
    required this.editing,
    required this.saving,
    required this.saveError,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.onEdit,
    required this.onSave,
    required this.onCancelEdit,
    required this.onLogout,
  });

  final MemberProfile profile;
  final GlobalKey profileKey;
  final bool editing;
  final bool saving;
  final String? saveError;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancelEdit;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final benefitLabel = profile.benefitBadgeLabel;

    return Stack(
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
                profile.tier,
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
                          label: profile.status.toUpperCase(),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.28),
                          foregroundColor: const Color(0xFFB6E8C8),
                        ),
                      ],
                    ),
                    if (benefitLabel != null) ...[
                      const SizedBox(height: 12),
                      AppBadge(
                        label: benefitLabel,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.22),
                        foregroundColor: const Color(0xFFB6E8C8),
                      ),
                    ],
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
                      profile.fullName,
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
                                profile.memberId,
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
                              profile.memberSince,
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
                        child: MembershipQrCode(value: profile.qrPayload),
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
                key: profileKey,
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
                            value: profile.fullName,
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          _InfoRow(
                            icon: Icons.mail_outline,
                            label: 'Email Address',
                            value: profile.email,
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: profile.phone.isEmpty
                                ? 'Not added'
                                : profile.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Edit Profile',
                      variant: AppButtonVariant.secondary,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      onPressed: onEdit,
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
                      onPressed: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (editing)
          _EditProfileSheet(
            nameCtrl: nameCtrl,
            emailCtrl: emailCtrl,
            phoneCtrl: phoneCtrl,
            saving: saving,
            error: saveError,
            onSave: onSave,
            onCancel: onCancelEdit,
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 16),
            AppButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
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
    required this.error,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool saving;
  final String? error;
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
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextField(label: 'Full Name', controller: nameCtrl),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email Address',
                      controller: emailCtrl,
                      readOnly: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Email is linked to your Firebase account and cannot be changed here.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
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
