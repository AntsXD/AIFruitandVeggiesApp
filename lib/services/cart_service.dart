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
    return CartSnapshot(items: List.unmodifiable(items), subtotal: subtotal);
  }

  Future<CartSnapshot> addItem({
    required String label,
    required double weightKg,
    required double unitPrice,
    required double total,
  }) async {
    _items.add(CartLineItem(
      label: label,
      weightKg: weightKg,
      unitPrice: unitPrice,
      total: total,
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
  });

  final String label;
  final double weightKg;
  final double unitPrice;
  final double total;

  factory CartLineItem.fromJson(Map<String, dynamic> json) => CartLineItem(
        label: json['label'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

class CartSnapshot {
  CartSnapshot({required this.items, required this.subtotal});

  final List<CartLineItem> items;
  final double subtotal;

  Map<String, dynamic> toJson() => {
        'items': items
            .map(
              (i) => {
                'label': i.label,
                'weight_kg': i.weightKg,
                'unit_price': i.unitPrice,
                'total': i.total,
              },
            )
            .toList(),
        'subtotal': subtotal,
      };

  factory CartSnapshot.fromJson(Map<String, dynamic> json) => CartSnapshot(
        items: (json['items'] as List<dynamic>)
            .map((e) => CartLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}
