import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_classifier/services/cart_service.dart';
import 'package:fruit_classifier/services/price_service.dart';
import 'package:fruit_classifier/services/receipt_service.dart';

void main() {
  group('PriceService Tests', () {
    final priceService = PriceService();

    test('fetches known item prices correctly', () async {
      final applePrice = await priceService.fetchPrice('Apple');
      expect(applePrice.label, equals('Apple'));
      expect(applePrice.pricePerKg, equals(3.49));

      final avocadoPrice = await priceService.fetchPrice('Avocado');
      expect(avocadoPrice.label, equals('Avocado'));
      expect(avocadoPrice.pricePerKg, equals(4.99));
    });

    test('returns default price for unknown items', () async {
      final unknownPrice = await priceService.fetchPrice('Dragonfruit');
      expect(unknownPrice.label, equals('Dragonfruit'));
      expect(unknownPrice.pricePerKg, equals(2.99));
    });
  });

  group('CartService Tests', () {
    final cartService = CartService();

    setUp(() async {
      await cartService.clearCart();
    });

    test('starts with empty cart', () async {
      final snapshot = await cartService.fetchCart();
      expect(snapshot.items, isEmpty);
      expect(snapshot.subtotal, equals(0.0));
    });

    test('adds items and calculates subtotal correctly', () async {
      var snapshot = await cartService.addItem(
        label: 'Apple',
        weightKg: 1.5,
        unitPrice: 3.49,
        total: 5.235,
      );

      expect(snapshot.items.length, equals(1));
      expect(snapshot.items.first.label, equals('Apple'));
      expect(snapshot.items.first.weightKg, equals(1.5));
      expect(snapshot.items.first.unitPrice, equals(3.49));
      expect(snapshot.items.first.total, equals(5.235));
      expect(snapshot.subtotal, equals(5.235));

      snapshot = await cartService.addItem(
        label: 'Banana',
        weightKg: 2.0,
        unitPrice: 1.99,
        total: 3.98,
      );

      expect(snapshot.items.length, equals(2));
      expect(snapshot.subtotal, closeTo(9.215, 0.0001));
    });

    test('clears cart successfully', () async {
      await cartService.addItem(
        label: 'Apple',
        weightKg: 1.0,
        unitPrice: 3.49,
        total: 3.49,
      );

      var snapshot = await cartService.fetchCart();
      expect(snapshot.items, isNotEmpty);

      await cartService.clearCart();
      snapshot = await cartService.fetchCart();
      expect(snapshot.items, isEmpty);
      expect(snapshot.subtotal, equals(0.0));
    });
  });

  group('ReceiptService Tests', () {
    final receiptService = ReceiptService();

    test('generates a valid receipt and token', () async {
      final cart = CartSnapshot(
        items: [
          CartLineItem(
            label: 'Apple',
            weightKg: 1.0,
            unitPrice: 3.49,
            total: 3.49,
          ),
        ],
        subtotal: 3.49,
      );

      final receiptLink = await receiptService.generateReceipt(cart);
      expect(receiptLink.token, isNotEmpty);
      expect(receiptLink.url, contains(receiptLink.token));
      expect(receiptLink.url, contains(':8765/receipt/'));

      final stored = ReceiptService.getReceipt(receiptLink.token);
      expect(stored, isNotNull);
      expect(stored!['token'], equals(receiptLink.token));
      expect(stored['subtotal'], equals(3.49));
      expect(stored['items'].first['label'], equals('Apple'));
    });
  });
}
