import '../config/app_config.dart';

class CartService {
  CartService();

  static final Map<String, List<CartLineItem>> _carts = {};

  List<CartLineItem> get _items {
    return _carts.putIfAbsent(AppConfig.sessionId, () => []);
  }

  Future<CartSnapshot> fetchCart() async {
    final items = _items;
    final subtotal = items.fold<double>(0.0, (sum, i) => sum + i.total);
    final totalCalories = items.fold<double>(0.0, (sum, i) => sum + i.calories);
    return CartSnapshot(
      items: List.unmodifiable(items),
      subtotal: subtotal,
      totalCalories: totalCalories,
    );
  }

  Future<CartSnapshot> addItem({
    required String label,
    required double weightKg,
    required double unitPrice,
    required double total,
    double calories = 0,
  }) async {
    _items.add(CartLineItem(
      label: label,
      weightKg: weightKg,
      unitPrice: unitPrice,
      total: total,
      calories: calories,
    ));
    return fetchCart();
  }

  Future<void> clearCart() async {
    _items.clear();
  }
}

class CartLineItem {
  CartLineItem({
    required this.label,
    required this.weightKg,
    required this.unitPrice,
    required this.total,
    this.calories = 0,
  });

  final String label;
  final double weightKg;
  final double unitPrice;
  final double total;
  final double calories;

  factory CartLineItem.fromJson(Map<String, dynamic> json) => CartLineItem(
        label: json['label'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
      );
}

class CartSnapshot {
  CartSnapshot({
    required this.items,
    required this.subtotal,
    this.totalCalories = 0,
  });

  final List<CartLineItem> items;
  final double subtotal;
  final double totalCalories;

  Map<String, dynamic> toJson() => {
        'items': items
            .map(
              (i) => {
                'label': i.label,
                'weight_kg': i.weightKg,
                'unit_price': i.unitPrice,
                'total': i.total,
                'calories': i.calories,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'total_calories': totalCalories,
      };

  factory CartSnapshot.fromJson(Map<String, dynamic> json) => CartSnapshot(
        items: (json['items'] as List<dynamic>)
            .map((e) => CartLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0,
      );
}
