import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../api/live_school_repository.dart';
import '../api/school_api.dart';
import '../api/school_repository.dart';
import 'school_provider.dart';
import 'school_state.dart';

final schoolApiClientProvider = Provider<AppApiClient>((ref) {
  return AppApiClient(ref.watch(dioProvider));
});

final schoolApiProvider = Provider<SchoolApi>((ref) {
  final client = ref.watch(schoolApiClientProvider);
  return SchoolApi(client: client);
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  final api = ref.watch(schoolApiProvider);
  return LiveSchoolRepository(api: api);
});

final schoolProvider = StateNotifierProvider<SchoolNotifier, SchoolState>((
  ref,
) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolNotifier(repository);
});
