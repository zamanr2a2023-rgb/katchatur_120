import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, dark }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (
          AppColors.primary,
          AppColors.primaryForeground,
          null as Border?
        ),
      AppButtonVariant.secondary => (
          AppColors.card,
          AppColors.ink,
          Border.all(color: AppColors.border, width: 1.2),
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          AppColors.primary,
          null,
        ),
      AppButtonVariant.dark => (
          AppColors.ink,
          AppColors.background,
          null,
        ),
    };

    final child = IconTheme(
      data: IconThemeData(color: fg, size: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: fg,
              ),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        elevation: variant == AppButtonVariant.primary ? 0 : 0,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: fullWidth ? double.infinity : null,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: border,
              boxShadow: variant == AppButtonVariant.primary
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}
