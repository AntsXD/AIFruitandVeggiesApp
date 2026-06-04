import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class PriceService {
  PriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PriceInfo> fetchPrice(String label) async {
    final encoded = Uri.encodeComponent(label);
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/prices/$encoded');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Price fetch failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PriceInfo(
      label: json['label'] as String,
      pricePerKg: (json['price_per_kg'] as num).toDouble(),
    );
  }
}

class PriceInfo {
  const PriceInfo({required this.label, required this.pricePerKg});

  final String label;
  final double pricePerKg;
}
