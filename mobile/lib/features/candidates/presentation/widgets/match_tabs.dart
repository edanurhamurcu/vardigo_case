import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/candidate.dart';

/// Segmented tab: track #F2F5F8 p4 radius 999; pills px8 py10, active #335CFF.
class MatchTabs extends StatelessWidget {
  const MatchTabs({
    super.key,
    required this.selected,
    required this.totalPerfect,
    required this.totalSimilar,
    required this.onChanged,
  });

  final CandidateTab selected;
  final int totalPerfect;
  final int totalSimilar;
  final ValueChanged<CandidateTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _Pill(
            label: '%100 Eşleşme ($totalPerfect)',
            active: selected == CandidateTab.perfect,
            onTap: () => onChanged(CandidateTab.perfect),
          ),
          _Pill(
            label: 'Benzer Personeller ($totalSimilar)',
            active: selected == CandidateTab.similar,
            onTap: () => onChanged(CandidateTab.similar),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.slate100,
              borderRadius: BorderRadius.circular(999),
              boxShadow: active ? AppShadows.tabActiveMatch : const [],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.tab12.copyWith(
                color: active ? AppColors.white : AppColors.slate500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
