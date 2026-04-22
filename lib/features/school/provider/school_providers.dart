import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/base_url.dart';
import '../../../core/network/token_provider.dart';
import '../api/live_school_repository.dart';
import '../api/school_api.dart';
import '../api/school_repository.dart';
import '../api/temporary_school_repository.dart';
import 'school_provider.dart';
import 'school_state.dart';

/// authSessionProvider(메모리 세션)에서 토큰을 읽어 API 헤더에 첨부
class _SessionTokenProvider implements TokenProvider {
  final Ref _ref;
  _SessionTokenProvider(this._ref);

  @override
  Future<String?> getAccessToken() async {
    return _ref.read(authSessionProvider).accessToken;
  }
}

final schoolApiClientProvider = Provider<AppApiClient>((ref) {
  return AppApiClient(
    baseUrl: apiBaseUrl,
    tokenProvider: _SessionTokenProvider(ref),
  );
});

final schoolApiProvider = Provider<SchoolApi>((ref) {
  final client = ref.watch(schoolApiClientProvider);
  return SchoolApi(client: client);
});

final useMockSchoolRepositoryProvider = Provider<bool>((ref) => false);

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  final useMock = ref.watch(useMockSchoolRepositoryProvider);

  if (useMock) {
    return const TemporarySchoolRepository();
  }

  final api = ref.watch(schoolApiProvider);
  return LiveSchoolRepository(api: api);
});

final schoolProvider =
    StateNotifierProvider<SchoolNotifier, SchoolState>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolNotifier(repository);
});
