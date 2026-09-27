import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/load_status.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/sort_chip.dart';
import '../../../core/widgets/square_icon_button.dart';
import '../../../core/widgets/state_views.dart';
import 'offers_controller.dart';
import 'widgets/offer_card.dart';
import 'widgets/offer_tabs.dart';

/// Sayfa 2 — Görüşme Talepleri (iş arayan)
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offersControllerProvider);
    final controller = ref.read(offersControllerProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  _Header(subtitle: state.tab.subtitle(state.pendingCount)),
                  const SizedBox(height: 16),
                  OfferTabs(selected: state.tab, onChanged: controller.selectTab),
                ],
              ),
            ),
          ),
          Expanded(child: _OfferList(state: state, controller: controller)),
        ],
      ),
    );
  }
}

/// Reference PNG shows the title left-aligned next to the back button
/// (the text spec says centered) — the PNG wins per the brief's source order.
class _Header extends StatelessWidget {
  const _Header({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SquareIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Geri',
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Görüşme Talepleri', style: AppTextStyles.title20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  subtitle,
                  key: ValueKey(subtitle),
                  style: AppTextStyles.caption12Medium.copyWith(color: AppColors.gray500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferList extends StatelessWidget {
  const _OfferList({required this.state, required this.controller});

  final OffersState state;
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final offers = state.visibleOffers;
    final isInitialLoad = state.status == LoadStatus.loading && offers.isEmpty;
    final hasError = state.status == LoadStatus.failure && offers.isEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 1 + (isInitialLoad || hasError || offers.isEmpty ? 1 : offers.length),
        // Use the list's context (not the item's) for snackbars: the item may be
        // removed right after accept/reject.
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: SortChip(label: state.sort.label, onTap: controller.cycleSort),
              ),
            );
          }

          if (isInitialLoad) return const LoadingView();
          if (hasError) {
            return ErrorView(message: state.errorMessage ?? 'Bir hata oluştu.', onRetry: controller.load);
          }
          if (offers.isEmpty) return EmptyView(message: state.tab.emptyMessage);

          final offer = offers[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OfferCard(
              key: ValueKey(offer.id),
              offer: offer,
              isBusy: state.busyOfferIds.contains(offer.id),
              onAccept: () => _handle(context, controller.accept(offer.id)),
              onReject: () => _handle(context, controller.reject(offer.id)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handle(BuildContext context, Future<OfferActionResult> action) async {
    final result = await action;
    if (!context.mounted || result.message.isEmpty) return;

    final color = switch (result) {
      OfferActionSuccess() => AppColors.slate700,
      OfferActionFailure() => AppColors.error,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message), backgroundColor: color));
  }
}
