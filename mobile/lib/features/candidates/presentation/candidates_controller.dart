import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/load_status.dart';
import '../data/candidates_repository.dart';
import '../domain/candidate.dart';

@immutable
class CandidatesState {
  const CandidatesState({
    this.tab = CandidateTab.perfect,
    this.sort = CandidateSort.recommended,
    this.status = LoadStatus.loading,
    this.errorMessage,
    this.candidates = const [],
    this.totalPerfect = 0,
    this.totalSimilar = 0,
    this.selectedIds = const {},
    this.isSending = false,
  });

  final CandidateTab tab;
  final CandidateSort sort;
  final LoadStatus status;
  final String? errorMessage;
  final List<Candidate> candidates;
  final int totalPerfect;
  final int totalSimilar;

  /// Selection lives on the client (spec) and survives tab/sort changes.
  final Set<String> selectedIds;
  final bool isSending;

  int get selectedCount => selectedIds.length;
  int get totalForTab => tab == CandidateTab.perfect ? totalPerfect : totalSimilar;

  /// CTA is disabled with 0 selected → an empty array never reaches the backend.
  bool get canSend => selectedIds.isNotEmpty && !isSending;

  CandidatesState copyWith({
    CandidateTab? tab,
    CandidateSort? sort,
    LoadStatus? status,
    ValueGetter<String?>? errorMessage,
    List<Candidate>? candidates,
    int? totalPerfect,
    int? totalSimilar,
    Set<String>? selectedIds,
    bool? isSending,
  }) {
    return CandidatesState(
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      candidates: candidates ?? this.candidates,
      totalPerfect: totalPerfect ?? this.totalPerfect,
      totalSimilar: totalSimilar ?? this.totalSimilar,
      selectedIds: selectedIds ?? this.selectedIds,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// Result of the "Görüşme Talebi Gönder" action; the UI decides how to show it.
sealed class SendOffersResult {
  const SendOffersResult();
}

final class SendOffersSuccess extends SendOffersResult {
  const SendOffersSuccess(this.count);
  final int count;
}

final class SendOffersFailure extends SendOffersResult {
  const SendOffersFailure(this.message);
  final String message;
}

class CandidatesController extends Notifier<CandidatesState> {
  bool _defaultSelectionApplied = false;

  CandidatesRepository get _repository => ref.read(candidatesRepositoryProvider);

  @override
  CandidatesState build() {
    Future.microtask(load);
    return const CandidatesState();
  }

  Future<void> load() async {
    final request = (tab: state.tab, sort: state.sort);
    state = state.copyWith(status: LoadStatus.loading, errorMessage: () => null);

    try {
      final page = await _repository.fetch(tab: request.tab, sort: request.sort);
      // Ignore stale responses if the user switched tab/sort meanwhile.
      if (!ref.mounted || request != (tab: state.tab, sort: state.sort)) return;

      var selected = state.selectedIds;
      // Reference: the top recommended candidate (Merve Y.) is pre-selected.
      if (!_defaultSelectionApplied && page.candidates.isNotEmpty) {
        selected = {page.candidates.first.id};
        _defaultSelectionApplied = true;
      }

      state = state.copyWith(
        status: LoadStatus.success,
        candidates: page.candidates,
        totalPerfect: page.totalPerfect,
        totalSimilar: page.totalSimilar,
        selectedIds: selected,
      );
    } on ApiException catch (e) {
      if (!ref.mounted || request != (tab: state.tab, sort: state.sort)) return;
      state = state.copyWith(status: LoadStatus.failure, errorMessage: () => e.message);
    }
  }

  void selectTab(CandidateTab tab) {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab, candidates: const []);
    load();
  }

  void cycleSort() {
    state = state.copyWith(sort: state.sort.next);
    load();
  }

  void toggleSelection(String candidateId) {
    final selected = {...state.selectedIds};
    if (!selected.remove(candidateId)) selected.add(candidateId);
    state = state.copyWith(selectedIds: selected);
  }

  Future<SendOffersResult> sendOffers() async {
    if (!state.canSend) {
      return const SendOffersFailure('En az bir personel seçmelisin.');
    }

    state = state.copyWith(isSending: true);
    try {
      final count = await _repository.sendOffers(state.selectedIds.toList());
      if (ref.mounted) state = state.copyWith(isSending: false, selectedIds: const {});
      return SendOffersSuccess(count);
    } on ApiException catch (e) {
      if (ref.mounted) state = state.copyWith(isSending: false);
      return SendOffersFailure(e.message);
    }
  }
}

final candidatesControllerProvider =
    NotifierProvider.autoDispose<CandidatesController, CandidatesState>(CandidatesController.new);
