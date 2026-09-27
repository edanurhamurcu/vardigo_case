import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/load_status.dart';
import '../data/offers_repository.dart';
import '../domain/offer.dart';

@immutable
class OffersState {
  const OffersState({
    this.tab = OfferTab.pending,
    this.sort = OfferSort.recommended,
    this.status = LoadStatus.loading,
    this.errorMessage,
    this.offers = const [],
    this.pendingCount = 0,
    this.busyOfferIds = const {},
  });

  final OfferTab tab;
  final OfferSort sort;
  final LoadStatus status;
  final String? errorMessage;
  final List<Offer> offers;
  final int pendingCount;

  /// Offers with an accept/reject request in flight (their buttons show a spinner).
  final Set<String> busyOfferIds;

  List<Offer> get visibleOffers {
    final sorted = [...offers];
    switch (sort) {
      case OfferSort.recommended:
        break; // server order
      case OfferSort.pay:
        sorted.sort((a, b) => b.payValue.compareTo(a.payValue));
      case OfferSort.expiring:
        sorted.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    }
    return sorted;
  }

  OffersState copyWith({
    OfferTab? tab,
    OfferSort? sort,
    LoadStatus? status,
    ValueGetter<String?>? errorMessage,
    List<Offer>? offers,
    int? pendingCount,
    Set<String>? busyOfferIds,
  }) {
    return OffersState(
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      offers: offers ?? this.offers,
      pendingCount: pendingCount ?? this.pendingCount,
      busyOfferIds: busyOfferIds ?? this.busyOfferIds,
    );
  }
}

sealed class OfferActionResult {
  const OfferActionResult(this.message);
  final String message;
}

final class OfferActionSuccess extends OfferActionResult {
  const OfferActionSuccess(super.message);
}

final class OfferActionFailure extends OfferActionResult {
  const OfferActionFailure(super.message);
}

class OffersController extends Notifier<OffersState> {
  OffersRepository get _repository => ref.read(offersRepositoryProvider);

  @override
  OffersState build() {
    Future.microtask(load);
    return const OffersState();
  }

  Future<void> load() async {
    final tab = state.tab;
    state = state.copyWith(status: LoadStatus.loading, errorMessage: () => null);

    try {
      final page = await _repository.fetch(tab);
      if (!ref.mounted || tab != state.tab) return;
      state = state.copyWith(
        status: LoadStatus.success,
        offers: page.offers,
        pendingCount: page.pendingCount,
      );
    } on ApiException catch (e) {
      if (!ref.mounted || tab != state.tab) return;
      state = state.copyWith(status: LoadStatus.failure, errorMessage: () => e.message);
    }
  }

  void selectTab(OfferTab tab) {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab, offers: const []);
    load();
  }

  void cycleSort() => state = state.copyWith(sort: state.sort.next);

  Future<OfferActionResult> accept(String offerId) =>
      _respond(offerId, accept: true);

  Future<OfferActionResult> reject(String offerId) =>
      _respond(offerId, accept: false);

  Future<OfferActionResult> _respond(String offerId, {required bool accept}) async {
    if (state.busyOfferIds.contains(offerId)) {
      return const OfferActionFailure('İşlem sürüyor…');
    }
    state = state.copyWith(busyOfferIds: {...state.busyOfferIds, offerId});

    try {
      if (accept) {
        await _repository.accept(offerId);
      } else {
        await _repository.reject(offerId);
      }
      if (!ref.mounted) return const OfferActionSuccess('');

      // The answered offer leaves "Bekleyen" and will show up under "Cevaplanan".
      state = state.copyWith(
        offers: state.offers.where((o) => o.id != offerId).toList(),
        pendingCount: state.pendingCount > 0 ? state.pendingCount - 1 : 0,
        busyOfferIds: {...state.busyOfferIds}..remove(offerId),
      );
      return OfferActionSuccess(
        accept ? 'İlgilendiğini işverene ilettik.' : 'Talep reddedildi.',
      );
    } on ApiException catch (e) {
      if (!ref.mounted) return OfferActionFailure(e.message);
      state = state.copyWith(busyOfferIds: {...state.busyOfferIds}..remove(offerId));
      // 409: expired or already answered on the server → refresh to show the truth.
      if (e.statusCode == 409) await load();
      return OfferActionFailure(e.message);
    }
  }
}

final offersControllerProvider =
    NotifierProvider.autoDispose<OffersController, OffersState>(OffersController.new);
