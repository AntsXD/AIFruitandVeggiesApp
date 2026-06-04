import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'cart_service.dart';

class ReceiptService {
  ReceiptService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ReceiptLink> generateReceipt(CartSnapshot cart) async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/receipt/generate');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cart': cart.toJson(),
        'base_url': AppConfig.backendBaseUrl,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Receipt generate failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ReceiptLink(
      token: json['token'] as String,
      url: json['url'] as String,
    );
  }
}

class ReceiptLink {
  const ReceiptLink({required this.token, required this.url});

  final String token;
  final String url;
}
