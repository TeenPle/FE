import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/home_repository.dart';
import '../api/mock_home_repository.dart';
import 'home_provider.dart';
import 'home_state.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return const MockHomeRepository();
});

final homeProvider =
StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository);
});