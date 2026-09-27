import 'package:flutter_test/flutter_test.dart';
import 'package:vardigo_case/core/utils/formatters.dart';
import 'package:vardigo_case/features/candidates/domain/candidate.dart';
import 'package:vardigo_case/features/offers/domain/offer.dart';

void main() {
  test('formatThousands uses Turkish separators', () {
    expect(formatThousands(25000), '25.000');
    expect(formatThousands(1500), '1.500');
    expect(formatThousands(999), '999');
  });

  test('Candidate.fromJson resolves asset urls', () {
    final candidate = Candidate.fromJson(
      {
        'id': 'w_merve',
        'name': 'Merve Y.',
        'rating': '4.9',
        'attend': '%100 katılım',
        'km': '4.9 km',
        'photo': '/assets/photos/merve.png',
        'online': true,
        'perfect': true,
        'score': 92,
        'expectedPay': 25000,
        'payMatches': true,
      },
      resolveAsset: (path) => 'http://host$path',
    );

    expect(candidate.photoUrl, 'http://host/assets/photos/merve.png');
    expect(candidate.expectedPay, 25000);
  });

  test('OfferTab labels and empty messages match the spec', () {
    expect(OfferTab.values.map((t) => t.label), ['Bekleyen', 'Cevaplanan', 'Süresi Dolan']);
    expect(OfferTab.pending.subtitle(12), '12 talep yanıt bekliyor');
    expect(OfferTab.expired.emptyMessage, 'Süresi dolan talep yok');
  });
}
