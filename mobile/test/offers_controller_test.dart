import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vardigo_case/core/network/api_exception.dart';
import 'package:vardigo_case/features/offers/data/offers_repository.dart';
import 'package:vardigo_case/features/offers/domain/offer.dart';
import 'package:vardigo_case/features/offers/presentation/offers_controller.dart';

Offer _offer(String id, {int pay = 45000, Duration expiresIn = const Duration(hours: 21)}) => Offer(
      id: id,
      title: 'Garson',
      place: 'Zarif Cheff Restaurant',
      pay: '45.000',
      payValue: pay,
      logoUrl: 'http://x/logo.svg',
      district: 'Kadıköy',
      when: '16 Ağu · 12:00 - 16:00',
      status: OfferStatus.pending,
      remain: '21 saat 0 dakika',
      expiresAt: DateTime.now().add(expiresIn),
    );

class FakeOffersRepository implements OffersRepository {
  final fetched = <OfferTab>[];
  ApiException? acceptError;

  @override
  Future<OffersPage> fetch(OfferTab tab) async {
    fetched.add(tab);
    if (tab != OfferTab.pending) return const OffersPage(pendingCount: 2, offers: []);
    return OffersPage(
      pendingCount: 2,
      offers: [
        _offer('o_1', pay: 32000, expiresIn: const Duration(hours: 3)),
        _offer('o_2', pay: 45000),
      ],
    );
  }

  @override
  Future<Offer> accept(String offerId) async {
    if (acceptError case final error?) throw error;
    return _offer(offerId);
  }

  @override
  Future<Offer> reject(String offerId) async => _offer(offerId);

  @override
  Future<OfferDetail> detail(String offerId) async =>
      OfferDetail(offer: _offer(offerId), city: 'İstanbul', note: 'Şube');
}

void main() {
  late FakeOffersRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeOffersRepository();
    container = ProviderContainer(
      overrides: [offersRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(offersControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);
  OffersState read() => container.read(offersControllerProvider);
  OffersController controller() => container.read(offersControllerProvider.notifier);

  test('accepting removes the offer from Bekleyen and decrements the count', () async {
    await settle();

    final result = await controller().accept('o_1');

    expect(result, isA<OfferActionSuccess>());
    expect(read().offers.map((o) => o.id), ['o_2']);
    expect(read().pendingCount, 1);
  });

  test('409 from the server shows the message and reloads the tab', () async {
    await settle();
    repository.acceptError = const ApiException(
      code: 'OFFER_EXPIRED',
      message: 'Teklifin süresi doldu',
      statusCode: 409,
    );

    final result = await controller().accept('o_1');

    expect(result.message, 'Teklifin süresi doldu');
    expect(repository.fetched, [OfferTab.pending, OfferTab.pending]);
  });

  test('switching tabs fetches that status', () async {
    await settle();
    controller().selectTab(OfferTab.answered);
    await settle();

    expect(repository.fetched.last, OfferTab.answered);
    expect(read().tab.subtitle(read().pendingCount), 'Cevaplanan talepler');
  });

  test('client-side sort by pay and by expiry', () async {
    await settle();

    controller().cycleSort(); // → Ücret
    expect(read().visibleOffers.first.id, 'o_2');

    controller().cycleSort(); // → Süresi Yakın
    expect(read().visibleOffers.first.id, 'o_1');
  });

  test('offers expiring within 6 hours are urgent', () {
    expect(_offer('a', expiresIn: const Duration(hours: 5)).isUrgent(), isTrue);
    expect(_offer('b', expiresIn: const Duration(hours: 21)).isUrgent(), isFalse);
  });
}
