import 'dart:io';
import 'dart:math';

import '../config/app_config.dart';
import 'cart_service.dart';

class ReceiptService {
  ReceiptService();

  // Store receipts in-memory
  static final Map<String, Map<String, dynamic>> _receiptStore = {};

  static Map<String, dynamic>? getReceipt(String token) {
    return _receiptStore[token];
  }

  static String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Set version to 4
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122
    values[8] = (values[8] & 0x3f) | 0x80;
    
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      // Look for a private IP address first (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            return ip;
          }
        }
      }
      // Fallback to any non-loopback
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (e) {
      // fallback
    }
    return '127.0.0.1';
  }

  Future<ReceiptLink> generateReceipt(CartSnapshot cart) async {
    final token = _generateUuid();
    final ip = await getLocalIp();
    final url = 'http://$ip:${AppConfig.espWebSocketPort}/receipt/$token';
    
    _receiptStore[token] = {
      'token': token,
      'items': cart.items.map((i) => {
        'label': i.label,
        'weight_kg': i.weightKg,
        'unit_price': i.unitPrice,
        'total': i.total,
      }).toList(),
      'subtotal': cart.subtotal,
    };

    return ReceiptLink(token: token, url: url);
  }
}

class ReceiptLink {
  const ReceiptLink({required this.token, required this.url});

  final String token;
  final String url;
}
