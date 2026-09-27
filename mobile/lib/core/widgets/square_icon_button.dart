import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'app_icon.dart';

/// 44×44 back / help button (radius 12, border #EAECF0, icon 20 #525866).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
  });

  final AppIcons icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: radius,
          border: Border.all(color: AppColors.slate200),
          boxShadow: AppShadows.squareButton,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(child: AppIcon(icon, color: AppColors.slate600)),
          ),
        ),
      ),
    );
  }
}
