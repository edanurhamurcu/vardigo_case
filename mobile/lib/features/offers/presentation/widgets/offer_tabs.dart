import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/offer.dart';

/// 3-way tab: track #F7F7F7 radius 54 p4, pills gap 4, py12 px4 radius 26,
/// active white + shadow (#171717), passive #A3A3A3.
class OfferTabs extends StatelessWidget {
  const OfferTabs({super.key, required this.selected, required this.onChanged});

  final OfferTab selected;
  final ValueChanged<OfferTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.weak50,
        borderRadius: BorderRadius.circular(54),
      ),
      child: Row(
        spacing: 4,
        children: [
          for (final tab in OfferTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      color: tab == selected ? AppColors.white : AppColors.weak50,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: tab == selected ? AppShadows.tabActiveOffers : const [],
                    ),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.tab13.copyWith(
                        color: tab == selected ? AppColors.strong : AppColors.soft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
