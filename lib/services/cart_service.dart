import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _sessionPath =>
      '${AppConfig.backendBaseUrl}/cart/${AppConfig.sessionId}';

  Future<CartSnapshot> fetchCart() async {
    final response = await _client.get(Uri.parse(_sessionPath));
    if (response.statusCode != 200) {
      throw Exception('Cart fetch failed: ${response.statusCode}');
    }
    return CartSnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CartSnapshot> addItem({
    required String label,
    required double weightKg,
    required double unitPrice,
    required double total,
  }) async {
    final uri = Uri.parse('$_sessionPath/add');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'label': label,
        'weight_kg': weightKg,
        'unit_price': unitPrice,
        'total': total,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Cart add failed: ${response.statusCode}');
    }
    return CartSnapshot.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> clearCart() async {
    final response = await _client.delete(Uri.parse(_sessionPath));
    if (response.statusCode != 200) {
      throw Exception('Cart clear failed: ${response.statusCode}');
    }
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
