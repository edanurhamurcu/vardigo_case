import '../network/api_client.dart';
import '../network/api_exception.dart';

enum UserRole { employer, worker }

/// Case auth: POST /auth/login { role } returns a fixed dev token.
/// Tokens are cached in memory per role; each feature asks for the role it needs.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  final Map<UserRole, String> _tokens = {};

  Future<String> tokenFor(UserRole role) async {
    final cached = _tokens[role];
    if (cached != null) return cached;

    final data = await _api.post('/auth/login', body: {'role': role.name});
    if (data case {'token': final String token}) {
      _tokens[role] = token;
      return token;
    }
    throw ApiException.badResponse;
  }
}
