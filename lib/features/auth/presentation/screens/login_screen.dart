import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  /// Optional in-app path to open after successful login (e.g. `/membership`).
  final String? redirectTo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  final _email = TextEditingController();
  final _password = TextEditingController();

  static const _allowedRedirects = {
    RoutePaths.home,
    RoutePaths.menu,
    RoutePaths.membership,
    RoutePaths.donate,
  };

  String get _safeRedirect {
    final raw = widget.redirectTo?.trim() ?? '';
    if (_allowedRedirects.contains(raw)) return raw;
    return RoutePaths.home;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_email.text.contains('@') || _password.text.length < 4) {
      setState(() => _error = 'Please check your email or password.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.instance.signInWithEmailPassword(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.go(_safeRedirect);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AuthService.mapFirebaseErrorToMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 12 : 0),
          child: Column(
            children: [
              SizedBox(
                height: 250 + topInset * 0.35,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/interior.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.25),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.45, 0.78, 1.0],
                          colors: [
                            AppColors.ink.withValues(alpha: 0.18),
                            AppColors.ink.withValues(alpha: 0.05),
                            AppColors.background.withValues(alpha: 0.72),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      right: 24,
                      bottom: 18,
                      child: Center(child: BrandLogo(size: LogoSize.lg)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                child: Column(
                  children: [
                    Text(
                      'Welcome to Bajatzu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to access your Bajatzu membership.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          final email = _email.text.trim();
                          context.pushNamed(
                            RouteNames.forgotPassword,
                            queryParameters: email.isEmpty
                                ? const <String, String>{}
                                : {'email': email},
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: _loading ? 'Signing in' : 'Log In',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'NEW HERE',
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.2,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.border, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      label: 'Create Account',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        final redirect = widget.redirectTo?.trim();
                        if (redirect != null && redirect.isNotEmpty) {
                          context.push(
                            '${RoutePaths.register}?redirect=${Uri.encodeComponent(redirect)}',
                          );
                        } else {
                          context.pushNamed(RouteNames.register);
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'A private membership for guests of Bajatzu.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedForeground,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
