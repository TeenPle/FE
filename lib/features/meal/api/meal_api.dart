import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_api_client.dart';
import '../../../core/network/dio_provider.dart';
import '../models/meal_model.dart';

class MealResponse {
  final List<MealModel> meals;
  final bool neisAvailable;

  const MealResponse({required this.meals, required this.neisAvailable});
}

final mealApiProvider = Provider<MealApi>((ref) {
  return MealApi(AppApiClient(ref.watch(dioProvider)));
});

class MealApi {
  final AppApiClient _client;

  MealApi(this._client);

  Future<MealResponse> getMeals({
    required int schoolId,
    required String from,
    required String to,
  }) async {
    final res = await _client.get(
      '/api/schools/$schoolId/meal',
      queryParameters: {'from': from, 'to': to},
    );
    final result = res['result'] as Map<String, dynamic>;
    final meals = (result['meals'] as List<dynamic>? ?? [])
        .map((e) => MealModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final neisAvailable = result['neisAvailable'] as bool? ?? true;
    return MealResponse(meals: meals, neisAvailable: neisAvailable);
  }
}
