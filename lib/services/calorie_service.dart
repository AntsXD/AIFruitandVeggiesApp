class CalorieService {
  const CalorieService();

  static const double _defaultKcalPer100g = 50;
  static const Map<String, double> _kcalPer100g = {
    "Apple": 52,
    "Banana": 89,
    "Cucumber": 15,
    "Orange": 47,
    "Potato": 77,
    "Tomato": 18,
  };

  Future<CalorieInfo> fetchCalories(String label) async {
    final kcal = _kcalPer100g[label] ?? _defaultKcalPer100g;
    return CalorieInfo(label: label, kcalPer100g: kcal);
  }
}

class CalorieInfo {
  const CalorieInfo({required this.label, required this.kcalPer100g});

  final String label;
  final double kcalPer100g;
}
