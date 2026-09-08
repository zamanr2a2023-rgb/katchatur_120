import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/membership/data/membership_status.dart';
import '../../../../services/membership_proof_storage.dart';
import '../../../../shared/widgets/app_button.dart';

/// Shared UI for picking review proof + platform (signup / resubmit).
class MembershipProofForm extends StatelessWidget {
  const MembershipProofForm({
    super.key,
    required this.proofFile,
    required this.platform,
    required this.onPickProof,
    required this.onClearProof,
    required this.onPlatformChanged,
    this.enabled = true,
  });

  final XFile? proofFile;
  final String platform;
  final VoidCallback onPickProof;
  final VoidCallback onClearProof;
  final ValueChanged<String> onPlatformChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review platform',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PlatformChip(
                label: 'Google',
                selected: platform == ReviewPlatform.google,
                enabled: enabled,
                onTap: () => onPlatformChanged(ReviewPlatform.google),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlatformChip(
                label: 'Tripadvisor',
                selected: platform == ReviewPlatform.tripadvisor,
                enabled: enabled,
                onTap: () => onPlatformChanged(ReviewPlatform.tripadvisor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Review proof screenshot',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload a screenshot of your Google or Tripadvisor review (jpg, png, or webp, max 5 MB).',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (proofFile == null)
          AppButton(
            label: 'Choose image',
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.image_outlined, size: 17),
            onPressed: enabled ? onPickProof : null,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    proofFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: enabled ? onClearProof : null,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

Future<XFile?> pickMembershipProof(BuildContext context) async {
  try {
    return await MembershipProofStorage.instance.pickProofImage();
  } catch (e) {
    if (!context.mounted) return null;
    final text = e.toString();
    final message = text.contains('channel-error') ||
            text.contains('Unable to establish connection')
        ? 'Image picker needs a full app restart after install. Stop the app and run flutter run again (hot reload is not enough).'
        : 'Could not open gallery: $e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    return null;
  }
}
