import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/school_repository.dart';
import '../api/temporary_school_repository.dart';
import 'school_provider.dart';
import 'school_state.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return const TemporarySchoolRepository();
});

final schoolProvider =
StateNotifierProvider<SchoolNotifier, SchoolState>((ref) {
  final repository = ref.watch(schoolRepositoryProvider);
  return SchoolNotifier(repository);
});