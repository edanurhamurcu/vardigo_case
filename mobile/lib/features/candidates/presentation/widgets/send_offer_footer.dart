import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/phone_frame.dart';

/// Sticky footer: #FBFBFB, top border #EBEBEB, pt20 px24.
/// CTA 44 high, radius 10, disabled at opacity .45 when nothing is selected.
class SendOfferFooter extends StatelessWidget {
  const SendOfferFooter({
    super.key,
    required this.count,
    required this.enabled,
    required this.isSending,
    required this.onPressed,
  });

  final int count;
  final bool enabled;
  final bool isSending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    final canTap = enabled && !isSending;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.weak,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: enabled || isSending ? 1 : 0.45,
              child: Semantics(
                button: true,
                enabled: canTap,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: radius,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: canTap ? onPressed : null,
                    child: SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSending)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          else
                            const AppIcon(AppIcons.send, color: AppColors.white),
                          const SizedBox(width: 8),
                          Text('Görüşme Talebi Gönder ($count)', style: AppTextStyles.label14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const BottomInset(),
          ],
        ),
      ),
    );
  }
}
