import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum LogoSize { sm, md, lg }

class BajatzuLogo extends StatelessWidget {
  const BajatzuLogo({
    super.key,
    this.size = LogoSize.md,
    this.tone = LogoTone.def,
  });

  final LogoSize size;
  final LogoTone tone;

  @override
  Widget build(BuildContext context) {
    final (fontSize, letterSpacing, subSize, subSpacing) = switch (size) {
      LogoSize.sm => (13.0, 3.8, 6.5, 2.8),
      LogoSize.md => (17.0, 5.0, 7.0, 3.2),
      LogoSize.lg => (28.0, 7.2, 8.0, 4.0),
    };
    final wordColor =
        tone == LogoTone.light ? AppColors.primaryForeground : AppColors.ink;
    final subColor = tone == LogoTone.light
        ? AppColors.primaryForeground.withValues(alpha: 0.72)
        : AppColors.mutedForeground;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: GoogleFonts.manrope(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: letterSpacing,
              color: wordColor,
              height: 1,
            ),
            children: [
              const TextSpan(text: 'BAJAT'),
              TextSpan(
                text: 'ZU',
                style: GoogleFonts.manrope(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: letterSpacing,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size == LogoSize.lg ? 8 : 6),
        Text(
          'RESTAURANT',
          style: GoogleFonts.manrope(
            fontSize: subSize,
            fontWeight: FontWeight.w500,
            letterSpacing: subSpacing,
            color: subColor,
            height: 1,
          ),
        ),
      ],
    );
  }
}

enum LogoTone { def, light }

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
