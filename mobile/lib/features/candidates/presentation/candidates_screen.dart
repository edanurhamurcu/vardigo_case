import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/load_status.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/sort_chip.dart';
import '../../../core/widgets/square_icon_button.dart';
import '../../../core/widgets/state_views.dart';
import 'candidates_controller.dart';
import 'widgets/candidate_card.dart';
import 'widgets/match_tabs.dart';
import 'widgets/send_offer_footer.dart';

/// Sayfa 1 — Eşleşen Personeller (işveren)
class CandidatesScreen extends ConsumerWidget {
  const CandidatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(candidatesControllerProvider);
    final controller = ref.read(candidatesControllerProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  _Header(total: state.totalForTab),
                  const SizedBox(height: 20),
                  MatchTabs(
                    selected: state.tab,
                    totalPerfect: state.totalPerfect,
                    totalSimilar: state.totalSimilar,
                    onChanged: controller.selectTab,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _CandidateList(state: state, controller: controller)),
          SendOfferFooter(
            count: state.selectedCount,
            enabled: state.canSend,
            isSending: state.isSending,
            onPressed: () => _sendOffers(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOffers(BuildContext context, CandidatesController controller) async {
    final result = await controller.sendOffers();
    if (!context.mounted) return;

    final message = switch (result) {
      SendOffersSuccess(:final count) => '$count kişiye görüşme talebi gönderildi.',
      SendOffersFailure(:final message) => message,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SquareIconButton(
          icon: AppIcons.back,
          semanticLabel: 'Geri',
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            children: [
              Text('$total personel bulundu', style: AppTextStyles.caption13),
              Text('Eşleşen Personeller', style: AppTextStyles.title16Medium),
            ],
          ),
        ),
        const SquareIconButton(icon: AppIcons.help, semanticLabel: 'Yardım'),
      ],
    );
  }
}

class _CandidateList extends StatelessWidget {
  const _CandidateList({required this.state, required this.controller});

  final CandidatesState state;
  final CandidatesController controller;

  @override
  Widget build(BuildContext context) {
    final isInitialLoad = state.status == LoadStatus.loading && state.candidates.isEmpty;
    final hasError = state.status == LoadStatus.failure && state.candidates.isEmpty;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        // index 0 = "N kişi seçildi" row, then the cards (or a state view).
        itemCount: 1 + (isInitialLoad || hasError || state.candidates.isEmpty ? 1 : state.candidates.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${state.selectedCount} kişi seçildi', style: AppTextStyles.title16Semi),
                  ),
                  SortChip(label: state.sort.label, onTap: controller.cycleSort),
                ],
              ),
            );
          }

          if (isInitialLoad) return const LoadingView();
          if (hasError) {
            return ErrorView(message: state.errorMessage ?? 'Bir hata oluştu.', onRetry: controller.load);
          }
          if (state.candidates.isEmpty) {
            return const EmptyView(message: 'Bu sekmede eşleşen personel yok');
          }

          final candidate = state.candidates[index - 1];
          return Padding(
            padding: EdgeInsets.only(top: index == 1 ? 0 : 10),
            child: CandidateCard(
              key: ValueKey(candidate.id),
              candidate: candidate,
              selected: state.selectedIds.contains(candidate.id),
              onTap: () => controller.toggleSelection(candidate.id),
            ),
          );
        },
      ),
    );
  }
}
