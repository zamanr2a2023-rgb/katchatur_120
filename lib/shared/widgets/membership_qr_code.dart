import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Real scannable QR code for a membership pass.
class MembershipQrCode extends StatelessWidget {
  const MembershipQrCode({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: QrImageView(
        data: value,
        version: QrVersions.auto,
        backgroundColor: AppColors.card,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.ink,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.ink,
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }
}
