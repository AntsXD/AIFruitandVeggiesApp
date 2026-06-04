class PriceService {
  PriceService({Object? client});

  static const double _defaultPrice = 2.99;
  static const Map<String, double> _pricesPerKg = {
    "Apple": 3.49,
    "Avocado": 4.99,
    "Banana": 1.99,
    "Beetroot": 2.49,
    "Cabbage": 1.79,
    "Cantaloupe": 3.29,
    "Carrot": 1.49,
    "Cauliflower": 2.99,
    "Celery": 2.29,
    "Cherry": 8.99,
    "Chestnut": 6.99,
    "Clementine": 3.99,
    "Corn": 1.29,
    "Cucumber": 1.99,
    "Dates": 7.99,
    "Eggplant": 2.79,
    "Ginger": 5.99,
    "Grape": 4.49,
    "Grapefruit": 2.99,
    "Guava": 4.99,
    "Kiwi": 3.99,
    "Lemon": 2.49,
    "Limes": 2.99,
    "Mandarine": 3.49,
    "Mango": 4.99,
    "Mangostan": 5.99,
    "Nut": 12.99,
    "Onion": 1.49,
    "Orange": 2.99,
    "Peach": 3.99,
    "Pear": 3.49,
    "Pepino": 4.49,
    "Pepper": 3.99,
    "Pineapple": 3.99,
    "Pitahaya": 6.99,
    "Plum": 3.49,
    "Pomegranate": 4.99,
    "Potato": 1.29,
    "Raspberry": 8.99,
    "Strawberry": 5.99,
    "Tomato": 2.49,
    "Watermelon": 1.99,
    "Zucchini": 2.29,
  };

  Future<PriceInfo> fetchPrice(String label) async {
    final price = _pricesPerKg[label] ?? _defaultPrice;
    return PriceInfo(
      label: label,
      pricePerKg: price,
    );
  }
}

class PriceInfo {
  const PriceInfo({required this.label, required this.pricePerKg});

  final String label;
  final double pricePerKg;
}
