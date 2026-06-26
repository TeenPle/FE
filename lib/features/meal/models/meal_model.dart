class MealModel {
  final String date;
  final List<String> dishes;
  final String calories;

  const MealModel({
    required this.date,
    required this.dishes,
    required this.calories,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      date: json['date'] as String? ?? '',
      dishes:
          (json['dishes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      calories: json['calories'] as String? ?? '',
    );
  }
}
