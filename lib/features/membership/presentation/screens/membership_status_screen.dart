import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/membership/data/member_profile.dart';
import '../../../../features/membership/data/membership_status.dart';
import '../../../../features/membership/presentation/widgets/membership_proof_form.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/membership_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/logo.dart';

/// Full-screen gate when Auth succeeds but Firestore status is not Active.
class MembershipStatusScreen extends StatefulWidget {
  const MembershipStatusScreen({
    super.key,
    required this.profile,
    this.onSignedOut,
  });

  final MemberProfile profile;
  final Future<void> Function()? onSignedOut;

  @override
  State<MembershipStatusScreen> createState() => _MembershipStatusScreenState();
}

class _MembershipStatusScreenState extends State<MembershipStatusScreen> {
  bool _resubmitting = false;
  bool _showResubmitForm = false;
  String? _error;
  XFile? _proofFile;
  String _platform = ReviewPlatform.google;

  MemberProfile get profile => widget.profile;

  Future<void> _logout() async {
    if (widget.onSignedOut != null) {
      await widget.onSignedOut!();
    } else {
      await AuthService.instance.signOut();
    }
  }

  Future<void> _pickProof() async {
    final file = await pickMembershipProof(context);
    if (file == null || !mounted) return;
    setState(() {
      _proofFile = file;
      _error = null;
    });
  }

  Future<void> _submitResubmit() async {
    if (_proofFile == null) {
      setState(() => _error = 'Please choose a new review proof image.');
      return;
    }
    setState(() {
      _resubmitting = true;
      _error = null;
    });
    try {
      await MembershipService.instance.resubmitProof(
        proofFile: _proofFile!,
        reviewPlatform: _platform,
      );
      if (!mounted) return;
      setState(() {
        _resubmitting = false;
        _showResubmitForm = false;
        _proofFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resubmitting = false;
        _error = AuthService.mapFirebaseErrorToMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = profile.status;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Center(child: BrandLogo(size: LogoSize.md)),
          const SizedBox(height: 28),
          _StatusHero(status: status),
          const SizedBox(height: 20),
          Text(
            _titleFor(status),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _bodyFor(status),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
          if (status == MembershipStatus.rejected) ...[
            if ((profile.rejectionReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF0C2BA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB42318),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!_showResubmitForm)
              AppButton(
                label: 'Submit new proof',
                onPressed: () => setState(() {
                  _showResubmitForm = true;
                  _error = null;
                }),
              )
            else ...[
              MembershipProofForm(
                proofFile: _proofFile,
                platform: _platform,
                enabled: !_resubmitting,
                onPickProof: _pickProof,
                onClearProof: () => setState(() => _proofFile = null),
                onPlatformChanged: (value) => setState(() => _platform = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'Resubmit for review',
                loading: _resubmitting,
                onPressed: _submitResubmit,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: _resubmitting
                    ? null
                    : () => setState(() {
                          _showResubmitForm = false;
                          _proofFile = null;
                          _error = null;
                        }),
              ),
            ],
          ],
          if (status == MembershipStatus.pending) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'You will unlock your membership QR once an admin approves your application. Keep the app installed — approval unlocks automatically.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.accentForeground,
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          AppButton(
            label: 'Log Out',
            variant: AppButtonVariant.ghost,
            icon: const Icon(
              Icons.logout,
              size: 17,
              color: AppColors.mutedForeground,
            ),
            onPressed: _logout,
          ),
          const SizedBox(height: 8),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  String _titleFor(String status) {
    switch (status) {
      case MembershipStatus.pending:
        return 'Membership pending';
      case MembershipStatus.rejected:
        return 'Membership rejected';
      case MembershipStatus.blocked:
        return 'Account blocked';
      case MembershipStatus.deactivated:
        return 'Account deactivated';
      default:
        return 'Membership unavailable';
    }
  }

  String _bodyFor(String status) {
    switch (status) {
      case MembershipStatus.pending:
        return 'Your membership is waiting for review.';
      case MembershipStatus.rejected:
        return 'Your application was not approved. You can submit a new review proof below.';
      case MembershipStatus.blocked:
        return 'This account is blocked. Contact support if you believe this is an error.';
      case MembershipStatus.deactivated:
        return 'This account is deactivated. Contact support to reactivate.';
      default:
        return 'Your membership cannot access the member home right now.';
    }
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (status) {
      MembershipStatus.pending => (
          Icons.hourglass_top_rounded,
          AppColors.primary,
          AppColors.primarySoft,
        ),
      MembershipStatus.rejected => (
          Icons.cancel_outlined,
          const Color(0xFFB42318),
          const Color(0xFFFFF4F2),
        ),
      MembershipStatus.blocked => (
          Icons.block,
          const Color(0xFFB42318),
          const Color(0xFFFFF4F2),
        ),
      MembershipStatus.deactivated => (
          Icons.pause_circle_outline,
          AppColors.mutedForeground,
          AppColors.muted,
        ),
      _ => (
          Icons.info_outline,
          AppColors.mutedForeground,
          AppColors.muted,
        ),
    };

    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 36, color: color),
      ),
    );
  }
}
