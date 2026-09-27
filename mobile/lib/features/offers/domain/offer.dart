enum OfferTab {
  pending(
    label: 'Bekleyen',
    apiStatus: 'pending',
    emptyMessage: 'Bekleyen talep yok',
  ),
  answered(
    label: 'Cevaplanan',
    apiStatus: 'answered',
    emptyMessage: 'Kabul veya red ettiğin talepler burada listelenir',
  ),
  expired(
    label: 'Süresi Dolan',
    apiStatus: 'expired',
    emptyMessage: 'Süresi dolan talep yok',
  );

  const OfferTab({required this.label, required this.apiStatus, required this.emptyMessage});

  final String label;
  final String apiStatus;
  final String emptyMessage;

  String subtitle(int pendingCount) => switch (this) {
        OfferTab.pending => '$pendingCount talep yanıt bekliyor',
        OfferTab.answered => 'Cevaplanan talepler',
        OfferTab.expired => 'Süresi dolan talepler',
      };
}

/// The backend has no sort param for offers, so sorting is done on the client.
enum OfferSort {
  recommended('Önerilen'),
  pay('Ücret'),
  expiring('Süresi Yakın');

  const OfferSort(this.label);

  final String label;

  OfferSort get next => values[(index + 1) % values.length];
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  expired;

  static OfferStatus parse(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => OfferStatus.expired);
}

class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.place,
    required this.pay,
    required this.payValue,
    required this.logoUrl,
    required this.district,
    required this.when,
    required this.status,
    required this.remain,
    required this.expiresAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json, {required String Function(String) resolveAsset}) {
    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      place: json['place'] as String,
      pay: json['pay'] as String,
      payValue: (json['payValue'] as num).toInt(),
      logoUrl: resolveAsset(json['logo'] as String),
      district: json['district'] as String,
      when: json['when'] as String,
      status: OfferStatus.parse(json['status'] as String),
      remain: json['remain'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Under this, the countdown is shown in red (reference: "5 saat 32 dakika" in red,
  /// "21 saat 32 dakika" in black). The threshold itself is our assumption.
  static const urgentThreshold = Duration(hours: 6);

  final String id;
  final String title;
  final String place;
  final String pay;
  final int payValue;
  final String logoUrl;
  final String district;
  final String when;
  final OfferStatus status;

  /// Server-formatted remaining time, e.g. "21 saat 32 dakika" (null unless pending).
  final String? remain;
  final DateTime expiresAt;

  bool isUrgent([DateTime? now]) => expiresAt.difference(now ?? DateTime.now()) < urgentThreshold;
}

class OffersPage {
  const OffersPage({required this.pendingCount, required this.offers});

  final int pendingCount;
  final List<Offer> offers;
}

class OfferDetail {
  const OfferDetail({required this.offer, required this.city, required this.note});

  final Offer offer;
  final String city;
  final String note;
}
