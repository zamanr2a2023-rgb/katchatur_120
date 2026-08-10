import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum LogoSize { sm, md, lg }

/// Classic "BAJATZU RESTAURANT" wordmark (text).
class BajatzuWordmark extends StatelessWidget {
  const BajatzuWordmark({
    super.key,
    this.size = LogoSize.md,
  });

  final LogoSize size;

  @override
  Widget build(BuildContext context) {
    final (fontSize, letterSpacing, subSize, subSpacing) = switch (size) {
      LogoSize.sm => (13.0, 3.8, 6.5, 2.8),
      LogoSize.md => (17.0, 5.0, 7.0, 3.2),
      LogoSize.lg => (28.0, 7.2, 8.0, 4.0),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BAJATZU',
          style: GoogleFonts.manrope(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
            color: AppColors.ink,
            height: 1,
          ),
        ),
        SizedBox(height: size == LogoSize.lg ? 8 : 6),
        Text(
          'RESTAURANT',
          style: GoogleFonts.manrope(
            fontSize: subSize,
            fontWeight: FontWeight.w500,
            letterSpacing: subSpacing,
            color: AppColors.mutedForeground,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// BAJATZU RESTAURANT wordmark inside a white pill — used everywhere logos appear.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = LogoSize.md,
    this.height,
    this.maxWidth,
  });

  final LogoSize size;
  /// Kept for call-site compatibility; ignored (wordmark sizes itself).
  final double? height;
  /// Kept for call-site compatibility; ignored (wordmark sizes itself).
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final (hPad, vPad) = switch (size) {
      LogoSize.sm => (12.0, 8.0),
      LogoSize.md => (16.0, 10.0),
      LogoSize.lg => (20.0, 14.0),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: BajatzuWordmark(size: size),
    );
  }
}

/// @Deprecated Prefer [BrandLogo]. Kept as alias for gradual migration.
typedef BajatzuLogo = BrandLogo;

/// Compact monogram mark used sparingly.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 40,
    this.fontSize = 17,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.primaryForeground,
    this.borderRadius = 12,
  });

  final double size;
  final double fontSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        'B',
        style: GoogleFonts.manrope(
          color: foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
