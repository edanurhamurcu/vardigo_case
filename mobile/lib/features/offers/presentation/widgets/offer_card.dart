import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/remote_images.dart';
import '../../data/offers_repository.dart';
import '../../domain/offer.dart';

/// Offer card — radius 20, border #EBEBEB, padding 16.
/// "Detayları Gör" expansion is ephemeral UI state, so it stays local to this widget.
class OfferCard extends StatefulWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  final Offer offer;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isPending = offer.status == OfferStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Summary(offer: offer),
          const SizedBox(height: 12),
          if (isPending)
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'İlgilenmiyorum',
                    icon: AppIcons.close,
                    background: AppColors.errorSoft,
                    foreground: AppColors.error,
                    isBusy: widget.isBusy,
                    onTap: widget.onReject,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    label: 'İlgileniyorum',
                    icon: AppIcons.check,
                    background: AppColors.green,
                    foreground: AppColors.white,
                    isBusy: widget.isBusy,
                    onTap: widget.onAccept,
                  ),
                ),
              ],
            )
          else
            _StatusBadge(status: offer.status),
          const SizedBox(height: 12),
          _DetailsButton(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) _DetailsPanel(offerId: offer.id),
          if (isPending && offer.remain != null) ...[
            const SizedBox(height: 10),
            _Countdown(remain: offer.remain!, urgent: offer.isUrgent()),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogoAvatar(url: offer.logoUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title18,
                    ),
                  ),
                  const AppIcon(AppIcons.money, size: 24),
                  const SizedBox(width: 4),
                  Text('₺${offer.pay}', style: AppTextStyles.pay18),
                ],
              ),
              Text(offer.place, style: AppTextStyles.caption12),
              const SizedBox(height: 8),
              Row(
                children: [
                  const AppIcon(AppIcons.pin, size: 14),
                  const SizedBox(width: 4),
                  Text(offer.district, style: AppTextStyles.caption12Medium),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.slate200,
                  ),
                  const AppIcon(AppIcons.date, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      offer.when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption12Medium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// height 36, radius 8, 14/500, icon 16.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final AppIcons icon;
  final Color background;
  final Color foreground;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: isBusy ? null : onTap,
        child: SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBusy)
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                )
              else
                AppIcon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label14.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the action buttons on "Cevaplanan" / "Süresi Dolan".
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (status) {
      OfferStatus.accepted => ('İlgileniyorum dedin', AppIcons.check, AppColors.greenLighter, AppColors.greenDark),
      OfferStatus.rejected => ('İlgilenmiyorum dedin', AppIcons.close, AppColors.errorSoft, AppColors.error),
      OfferStatus.expired || OfferStatus.pending => ('Teklifin süresi doldu', AppIcons.alarm, AppColors.weak50, AppColors.sub),
    };

    return Container(
      height: 36,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.label14.copyWith(color: foreground)),
        ],
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.stroke),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(AppIcons.eye, color: AppColors.sub),
              const SizedBox(width: 8),
              Text(
                expanded ? 'Detayları Gizle' : 'Detayları Gör',
                style: AppTextStyles.label14.copyWith(color: AppColors.sub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spec: "kartın altına 2 satırlık düz metin yeter" — loaded from GET /offers/:id.
class _DetailsPanel extends ConsumerWidget {
  const _DetailsPanel({required this.offerId});

  final String offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(offerDetailProvider(offerId));
    final style = AppTextStyles.body14;

    final Widget content = switch (detail) {
      AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konum: ${value.offer.district}, ${value.city} · ${value.note}', style: style),
            Text('Ücret: ₺${value.offer.pay} · Saat: ${value.offer.when}', style: style),
          ],
        ),
      AsyncError() => Text('Detaylar yüklenemedi.', style: style),
      _ => Text('Yükleniyor…', style: style),
    };

    return Padding(padding: const EdgeInsets.only(top: 12), child: content);
  }
}

/// "Teklifin sonlanmasına **21 saat 32 dakika** kaldı." — red when urgent (reference).
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remain, required this.urgent});

  final String remain;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(AppIcons.alarm, size: 16, color: urgent ? AppColors.error : null),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.caption12.copyWith(color: AppColors.strong),
              children: [
                const TextSpan(text: 'Teklifin sonlanmasına '),
                TextSpan(
                  text: remain,
                  style: AppTextStyles.caption12Bold.copyWith(
                    color: urgent ? AppColors.error : AppColors.strong,
                  ),
                ),
                const TextSpan(text: ' kaldı.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
