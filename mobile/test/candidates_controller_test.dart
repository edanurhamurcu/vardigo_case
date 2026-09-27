import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vardigo_case/core/network/api_exception.dart';
import 'package:vardigo_case/core/utils/load_status.dart';
import 'package:vardigo_case/features/candidates/data/candidates_repository.dart';
import 'package:vardigo_case/features/candidates/domain/candidate.dart';
import 'package:vardigo_case/features/candidates/presentation/candidates_controller.dart';

Candidate _candidate(String id, {int score = 90}) => Candidate(
      id: id,
      name: id,
      rating: '4.9',
      attend: '%100 katılım',
      km: '1 km',
      photoUrl: 'http://x/$id.png',
      online: true,
      perfect: score >= 80,
      score: score,
    );

class FakeCandidatesRepository implements CandidatesRepository {
  final requests = <({CandidateTab tab, CandidateSort sort})>[];
  final sent = <List<String>>[];
  ApiException? sendError;

  @override
  Future<CandidatesPage> fetch({required CandidateTab tab, required CandidateSort sort}) async {
    requests.add((tab: tab, sort: sort));
    return CandidatesPage(
      totalPerfect: 26,
      totalSimilar: 16,
      candidates: [_candidate('w_merve'), _candidate('w_ferhat', score: 88)],
    );
  }

  @override
  Future<int> sendOffers(List<String> candidateIds) async {
    if (sendError case final error?) throw error;
    sent.add(candidateIds);
    return candidateIds.length;
  }
}

void main() {
  late FakeCandidatesRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCandidatesRepository();
    container = ProviderContainer(
      overrides: [candidatesRepositoryProvider.overrideWithValue(repository)],
    );
    // Keep the autoDispose provider alive during the test.
    container.listen(candidatesControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  CandidatesState read() => container.read(candidatesControllerProvider);
  CandidatesController controller() => container.read(candidatesControllerProvider.notifier);

  test('loads candidates and pre-selects the top recommended one', () async {
    await settle();

    expect(read().status, LoadStatus.success);
    expect(read().candidates, hasLength(2));
    expect(read().totalPerfect, 26);
    expect(read().selectedIds, {'w_merve'});
  });

  test('sort cycles Önerilen → En Yakın → Puan and refetches', () async {
    await settle();

    controller().cycleSort();
    await settle();
    controller().cycleSort();
    await settle();

    expect(read().sort, CandidateSort.rating);
    expect(repository.requests.map((r) => r.sort), [
      CandidateSort.recommended,
      CandidateSort.near,
      CandidateSort.rating,
    ]);
  });

  test('cannot send with an empty selection', () async {
    await settle();
    controller().toggleSelection('w_merve'); // deselect

    expect(read().canSend, isFalse);
    final result = await controller().sendOffers();

    expect(result, isA<SendOffersFailure>());
    expect(repository.sent, isEmpty);
  });

  test('sends selected ids and clears the selection', () async {
    await settle();
    controller().toggleSelection('w_ferhat');

    final result = await controller().sendOffers();

    expect(result, isA<SendOffersSuccess>());
    expect(repository.sent.single, unorderedEquals(['w_merve', 'w_ferhat']));
    expect(read().selectedIds, isEmpty);
  });

  test('surfaces the backend message on failure', () async {
    await settle();
    repository.sendError = const ApiException(
      code: 'OFFER_EXISTS',
      message: 'Bu personele zaten açık bir talep var: Merve Y.',
      statusCode: 409,
    );

    final result = await controller().sendOffers();

    expect(result, isA<SendOffersFailure>());
    expect((result as SendOffersFailure).message, contains('Merve'));
    expect(read().isSending, isFalse);
    expect(read().selectedIds, {'w_merve'}); // kept so the user can adjust
  });
}
