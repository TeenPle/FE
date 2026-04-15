import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/token_provider.dart';
import '../api/live_school_repository.dart';
import '../api/school_api.dart';
import '../api/school_repository.dart';
import '../api/temporary_school_repository.dart';
import 'school_provider.dart';
import 'school_state.dart';

class DummyTokenProvider implements TokenProvider {
  @override
  Future<String?> getAccessToken() async {
    return null;
  }
}

final schoolTokenProviderProvider = Provider<TokenProvider>((ref) {
  return DummyTokenProvider();
});

final schoolApiClientProvider = Provider<AppApiClient>((ref) {
  final tokenProvider = ref.watch(schoolTokenProviderProvider);

  return AppApiClient(
    baseUrl: 'http://10.0.2.2:8080',
    tokenProvider: tokenProvider,
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