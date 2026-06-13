class PriceService {
  const PriceService();

  static const double _defaultPrice = 2.99;
  static const Map<String, double> _pricesPerKg = {
    "Apple": 3.49,
    "Banana": 1.99,
    "Cucumber": 1.99,
    "Orange": 2.99,
    "Potato": 1.29,
    "Tomato": 2.49,
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
