import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_checkbox.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/remote_images.dart';
import '../../domain/candidate.dart';

/// Candidate card — radius 20, px16 py12.
/// Selected: #EBF1FF background, no border, 4px blue strip on the left
/// (CSS "inset 4px 0 0 #335CFF"), filled checkbox.
///
/// Selecting plays a short "push" animation: the card nudges right and springs
/// back while the strip slides in. The resting state matches the reference.
class CandidateCard extends StatefulWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final Candidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> with TickerProviderStateMixin {
  static const _radius = BorderRadius.all(Radius.circular(20));
  static const _nudgeDistance = 6.0;

  /// 0 → 1: strip width 0 → 4px.
  late final AnimationController _strip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: widget.selected ? 1 : 0,
  );

  /// Drives the right-and-back nudge.
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  late final Animation<double> _nudgeOffset = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: _nudgeDistance).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: _nudgeDistance, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
  ]).animate(_nudge);

  late final Animation<double> _stripWidth = CurvedAnimation(
    parent: _strip,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;

    if (widget.selected) {
      _strip.forward();
      // Respect the OS "reduce motion" setting.
      if (!MediaQuery.disableAnimationsOf(context)) _nudge.forward(from: 0);
    } else {
      _strip.reverse();
    }
  }

  @override
  void dispose() {
    _strip.dispose();
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    final selected = widget.selected;

    return Semantics(
      button: true,
      selected: selected,
      label: '${candidate.name}, puan ${candidate.rating}, ${candidate.attend}, ${candidate.km}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_strip, _nudge]),
          // The card body is built once and only moved/overpainted per frame.
          builder: (context, child) => Transform.translate(
            offset: Offset(_nudgeOffset.value, 0),
            child: CustomPaint(
              // Painted over the whole card (border box) so the strip hugs the outer
              // rounded corners exactly like the CSS inset shadow in the reference.
              foregroundPainter: _stripWidth.value > 0
                  ? _InsetLeftStripPainter(width: 4 * _stripWidth.value)
                  : null,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLighter : AppColors.white,
              borderRadius: _radius,
              // Transparent border when selected keeps the content from shifting by 1px.
              border: Border.all(color: selected ? const Color(0x00000000) : AppColors.slate200),
              boxShadow: selected ? AppShadows.cardSelected : AppShadows.card,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    PersonAvatar(url: candidate.photoUrl, online: candidate.online),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title18,
                          ),
                          const SizedBox(height: 4),
                          _MetaRow(candidate: candidate),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppCheckbox(checked: selected),
                  ],
                ),
                if (candidate.expectedPay case final pay?) ...[
                  const SizedBox(height: 12),
                  _PayExpectation(
                    pay: pay,
                    matches: candidate.payMatches ?? false,
                    onSelectedCard: selected,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recreates CSS `box-shadow: inset 4px 0 0 #335CFF` on a rounded card:
/// the card's rounded rect minus the same rect shifted [width] px to the right.
/// The result follows the corner curves (a crescent) instead of a flat bar that
/// gets clipped away at the corners.
class _InsetLeftStripPainter extends CustomPainter {
  const _InsetLeftStripPainter({required this.width});

  final double width;

  static const _radius = Radius.circular(20);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, _radius);
    final strip = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(outer.shift(Offset(width, 0))),
    );
    canvas.drawPath(strip, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_InsetLeftStripPainter oldDelegate) => oldDelegate.width != width;
}

/// ★ 4.9 | 🛡 %100 katılım | 📍 4.9 km  — 12/500 slate-700, icon-text gap 4.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption12Medium;
    // scaleDown keeps the row on one line on narrow screens / large text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const AppIcon(AppIcons.star, size: 16, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(candidate.rating, style: style),
          const _Separator(),
          const AppIcon(AppIcons.shield, size: 16),
          const SizedBox(width: 4),
          Text(candidate.attend, style: style),
          const _Separator(),
          const AppIcon(AppIcons.pin, size: 14),
          const SizedBox(width: 4),
          Text(candidate.km, style: style),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.slate200,
    );
  }
}

/// "Ücret beklentisi uyuşuyor · ₺25.000 / ay" strip — present in the reference PNG
/// (not in the text spec); green when it matches the job's pay, orange otherwise.
class _PayExpectation extends StatelessWidget {
  const _PayExpectation({required this.pay, required this.matches, required this.onSelectedCard});

  final int pay;
  final bool matches;
  final bool onSelectedCard;

  @override
  Widget build(BuildContext context) {
    final color = matches ? AppColors.green : AppColors.warning;
    final style = AppTextStyles.label14.copyWith(color: color, fontWeight: FontWeight.w400);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onSelectedCard ? AppColors.white.withValues(alpha: 0.6) : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.money, size: 16, color: matches ? null : AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              matches ? 'Ücret beklentisi uyuşuyor' : 'Ücret beklentisi uyuşmuyor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Text('₺${formatThousands(pay)} / ay', style: style.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
