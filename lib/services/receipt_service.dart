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

  /// Renders a stored receipt map as a self-contained HTML page styled like a
  /// classic thermal-printer receipt. Keeps JSON consumers happy via Accept:
  /// application/json on the server side; browsers get this pretty view.
  static String buildReceiptHtml(Map<String, dynamic> receipt) {
    final items =
        (receipt['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final subtotal = (receipt['subtotal'] as num).toDouble();
    final token = receipt['token']?.toString() ?? '';
    final itemCount =
        (receipt['item_count'] as num?)?.toInt() ?? items.length;
    final totalCalories =
        (receipt['total_calories'] as num?)?.toInt() ?? 0;
    final createdAt = receipt['created_at'] is String
        ? DateTime.tryParse(receipt['created_at'] as String)?.toLocal()
        : null;

    String money(num v) => '\$${v.toStringAsFixed(2)}';
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr = createdAt == null
        ? '&nbsp;'
        : '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)} '
            '${two(createdAt.hour)}:${two(createdAt.minute)}';
    final shortToken =
        token.length >= 8 ? token.substring(0, 8).toUpperCase() : token;

    final rows = StringBuffer();
    for (final it in items) {
      final label = esc((it['label'] ?? '').toString());
      final weight = (it['weight_kg'] as num).toDouble();
      final unitPrice = (it['unit_price'] as num).toDouble();
      final total = (it['total'] as num).toDouble();
      final kcal = (it['calories'] as num?)?.toInt() ?? 0;
      rows.writeln('''
      <div class="item">
        <div class="item-name">$label</div>
        <div class="item-detail">
          <span class="item-qty">${weight.toStringAsFixed(3)} kg @ ${money(unitPrice)}/kg</span>
          <span class="item-total">${money(total)}</span>
        </div>${kcal > 0 ? '''
        <div class="item-cal">$kcal kcal</div>''' : ''}
      </div>''');
    }

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Receipt</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  html,body{min-height:100%}
  body{background:#e7e9ec;font-family:'Courier New',Courier,monospace;
    display:flex;justify-content:center;padding:24px 12px;-webkit-print-color-adjust:exact;print-color-adjust:exact}
  .receipt{position:relative;background:#fff;width:100%;max-width:330px;
    padding:30px 24px 22px;box-shadow:0 6px 26px rgba(0,0,0,.13);
    -webkit-mask-image:radial-gradient(circle at 0 100%,transparent 6px,#000 6.5px),radial-gradient(circle at 100% 100%,transparent 6px,#000 6.5px);
    mask-image:radial-gradient(circle at 0 100%,transparent 6px,#000 6.5px),radial-gradient(circle at 100% 100%,transparent 6px,#000 6.5px)}
  .header{text-align:center}
  .logo{display:flex;justify-content:center;margin-bottom:6px}
  .store{font-size:21px;font-weight:700;letter-spacing:1.5px;color:#2e7d32}
  .tagline{font-size:11px;color:#7a7a7a;margin-top:3px;letter-spacing:1px}
  .meta{font-size:11px;color:#555;margin:14px 0 0;line-height:1.7}
  .meta .row{display:flex;justify-content:space-between;max-width:240px;margin:0 auto}
  hr.dash{border:none;border-top:1px dashed #bbb;margin:13px 0}
  .item{margin:9px 0}
  .item-name{font-weight:700;font-size:14px}
  .item-detail{display:flex;justify-content:space-between;gap:10px;font-size:12px;margin-top:2px}
  .item-qty{color:#8a8a8a}
  .item-total{font-weight:700;white-space:nowrap}
  .item-cal{font-size:11px;color:#2e7d32;margin-top:2px}
  .totals{font-size:13px;margin-top:4px}
  .total-row{display:flex;justify-content:space-between;padding:3px 0;color:#555}
  .grand{display:flex;justify-content:space-between;font-size:18px;font-weight:700;
    border-top:2px solid #333;margin-top:9px;padding-top:10px}
  .barcode{height:44px;margin:18px auto 4px;width:80%;
    background-color:#fff;
    background-image:
      repeating-linear-gradient(90deg,#111 0 1px,transparent 1px 3px),
      repeating-linear-gradient(90deg,#111 0 4px,transparent 4px 7px),
      repeating-linear-gradient(90deg,#111 0 2px,transparent 2px 9px);
    background-size:7px 100%,11px 100%,23px 100%}
  .barcode-num{text-align:center;font-size:12px;letter-spacing:3px;color:#333}
  .footer{text-align:center;font-size:11px;color:#7a7a7a;margin-top:14px;line-height:1.7}
</style>
</head>
<body>
  <div class="receipt">
    <div class="header">
      <div class="logo">
        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#2e7d32" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
          <path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/>
          <path d="M2 21c0-3 1.85-5.36 5.08-6"/>
        </svg>
      </div>
      <div class="store">LEAM-Tech</div>
      <div class="tagline">SMART WEIGH &middot; CHECKOUT</div>
    </div>
    <div class="meta">
      <div class="row"><span>Date</span><span>$dateStr</span></div>
      <div class="row"><span>Receipt #</span><span>$shortToken</span></div>
    </div>
    <hr class="dash">
    $rows
    <hr class="dash">
    <div class="totals">
      <div class="total-row"><span>Items</span><span>$itemCount</span></div>
      <div class="total-row"><span>Calories</span><span>$totalCalories kcal</span></div>
      <div class="grand"><span>TOTAL</span><span>${money(subtotal)}</span></div>
    </div>
    <hr class="dash">
    <div class="barcode" aria-hidden="true"></div>
    <div class="barcode-num">* $shortToken *</div>
    <div class="footer">
      Thank you for shopping with us!<br>
      Have a fresh day &middot; Come again soon
    </div>
  </div>
</body>
</html>
''';
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
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'items': cart.items.map((i) => {
        'label': i.label,
        'weight_kg': i.weightKg,
        'unit_price': i.unitPrice,
        'total': i.total,
        'calories': i.calories.round(),
      }).toList(),
      'item_count': cart.items.length,
      'subtotal': cart.subtotal,
      'total_calories': cart.totalCalories.round(),
    };

    return ReceiptLink(token: token, url: url);
  }
}

class ReceiptLink {
  const ReceiptLink({required this.token, required this.url});

  final String token;
  final String url;
}
