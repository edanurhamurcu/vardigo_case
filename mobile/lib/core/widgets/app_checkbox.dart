import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import 'app_icon.dart';

/// 20×20, radius 6. Empty: border #CACFD8. Checked: filled #335CFF with a white tick.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? AppColors.primary : AppColors.slate300),
      ),
      child: checked
          ? const Center(child: AppIcon(AppIcons.check, size: 16, color: AppColors.white))
          : null,
    );
  }
}
