import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/candidate.dart';

/// Contract used by the presentation layer (lets tests swap in a fake).
abstract interface class CandidatesRepository {
  Future<CandidatesPage> fetch({required CandidateTab tab, required CandidateSort sort});

  /// Sends interview requests; returns how many offers were created.
  Future<int> sendOffers(List<String> candidateIds);
}

class ApiCandidatesRepository implements CandidatesRepository {
  ApiCandidatesRepository(this._api, this._auth);

  final ApiClient _api;
  final AuthRepository _auth;

  @override
  Future<CandidatesPage> fetch({required CandidateTab tab, required CandidateSort sort}) async {
    final token = await _auth.tokenFor(UserRole.employer);
    final data = await _api.get(
      '/candidates',
      query: {'tab': tab.name, 'sort': sort.name},
      token: token,
    );

    return parseResponse(() {
      final json = data! as Map<String, dynamic>;
      return CandidatesPage(
        totalPerfect: (json['totalPerfect'] as num).toInt(),
        totalSimilar: (json['totalSimilar'] as num).toInt(),
        candidates: (json['candidates'] as List<dynamic>)
            .map((e) => Candidate.fromJson(e as Map<String, dynamic>, resolveAsset: AppConfig.assetUrl))
            .toList(),
      );
    });
  }

  @override
  Future<int> sendOffers(List<String> candidateIds) async {
    final token = await _auth.tokenFor(UserRole.employer);
    final data = await _api.post('/offers', body: {'workerIds': candidateIds}, token: token);
    return parseResponse(() => ((data! as Map<String, dynamic>)['created'] as List<dynamic>).length);
  }
}

final candidatesRepositoryProvider = Provider<CandidatesRepository>(
  (ref) => ApiCandidatesRepository(ref.watch(apiClientProvider), ref.watch(authRepositoryProvider)),
);
