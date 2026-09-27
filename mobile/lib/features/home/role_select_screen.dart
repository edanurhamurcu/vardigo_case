import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../candidates/presentation/candidates_screen.dart';
import '../offers/presentation/offers_screen.dart';

/// Demo entry point: the case has one fixed employer and one fixed worker account.
/// Not part of the reference designs — kept intentionally minimal.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.weak,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('VardiGO', textAlign: TextAlign.center, style: AppTextStyles.title20),
              const SizedBox(height: 4),
              Text(
                'Demo hesabı seç',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption13,
              ),
              const SizedBox(height: 32),
              _RoleButton(
                title: 'İşveren olarak devam et',
                subtitle: 'Eşleşen personelleri gör, görüşme talebi gönder',
                filled: true,
                onTap: () => _open(context, const CandidatesScreen()),
              ),
              const SizedBox(height: 12),
              _RoleButton(
                title: 'İş arayan olarak devam et',
                subtitle: 'Gelen görüşme taleplerini yanıtla',
                filled: false,
                onTap: () => _open(context, const OffersScreen()),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final foreground = filled ? AppColors.white : AppColors.slate700;

    return Material(
      color: filled ? AppColors.primary : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: filled ? BorderSide.none : const BorderSide(color: AppColors.slate200),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.title16Medium.copyWith(color: foreground)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption12.copyWith(
                  color: filled ? AppColors.primaryLight : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
