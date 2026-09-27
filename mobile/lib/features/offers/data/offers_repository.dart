import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/offer.dart';

abstract interface class OffersRepository {
  Future<OffersPage> fetch(OfferTab tab);
  Future<Offer> accept(String offerId);
  Future<Offer> reject(String offerId);
  Future<OfferDetail> detail(String offerId);
}

class ApiOffersRepository implements OffersRepository {
  ApiOffersRepository(this._api, this._auth);

  final ApiClient _api;
  final AuthRepository _auth;

  Future<String> get _token => _auth.tokenFor(UserRole.worker);

  @override
  Future<OffersPage> fetch(OfferTab tab) async {
    final data = await _api.get('/offers', query: {'status': tab.apiStatus}, token: await _token);
    return parseResponse(() {
      final json = data! as Map<String, dynamic>;
      return OffersPage(
        pendingCount: (json['pendingCount'] as num).toInt(),
        offers: (json['offers'] as List<dynamic>)
            .map((e) => _offerFromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });
  }

  @override
  Future<Offer> accept(String offerId) => _respond(offerId, 'accept');

  @override
  Future<Offer> reject(String offerId) => _respond(offerId, 'reject');

  @override
  Future<OfferDetail> detail(String offerId) async {
    final data = await _api.get('/offers/$offerId', token: await _token);
    return parseResponse(() {
      final json = data! as Map<String, dynamic>;
      return OfferDetail(
        offer: _offerFromJson(json),
        city: json['city'] as String,
        note: json['note'] as String,
      );
    });
  }

  Future<Offer> _respond(String offerId, String action) async {
    final data = await _api.post('/offers/$offerId/$action', token: await _token);
    return parseResponse(() => _offerFromJson(data! as Map<String, dynamic>));
  }

  Offer _offerFromJson(Map<String, dynamic> json) =>
      Offer.fromJson(json, resolveAsset: AppConfig.assetUrl);
}

final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => ApiOffersRepository(ref.watch(apiClientProvider), ref.watch(authRepositoryProvider)),
);

/// Lazily loaded when the user taps "Detayları Gör".
final offerDetailProvider = FutureProvider.autoDispose.family<OfferDetail, String>(
  (ref, offerId) => ref.watch(offersRepositoryProvider).detail(offerId),
);
