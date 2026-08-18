import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _email;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail?.trim() ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (_loading) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.mapFirebaseErrorToMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.card,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.goNamed(RouteNames.login),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const BrandLogo(size: LogoSize.sm),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      48,
                      24,
                      48 + MediaQuery.viewInsetsOf(context).bottom * 0.1,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.vpn_key_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your email address and we'll send you instructions to reset your password.",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_error != null) ...[
                          FormErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],
                        AppTextField(
                          label: 'Email Address',
                          controller: _email,
                          hint: 'Enter your email address',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Send Reset Link',
                          loading: _loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Back to Login',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => context.goNamed(RouteNames.login),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_sent)
            Container(
              color: AppColors.ink.withValues(alpha: 0.4),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Check Your Email',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We've sent a password reset link to ${_email.text.trim()}.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'If you do not see it in a few minutes, check your Spam or Junk folder. '
                        'The email is usually from noreply@...firebaseapp.com.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.mutedForeground,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Back to Login',
                        onPressed: () => context.goNamed(RouteNames.login),
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
