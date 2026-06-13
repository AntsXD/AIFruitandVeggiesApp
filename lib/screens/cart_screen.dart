import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/cart_service.dart';
import '../services/receipt_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.cartService,
    this.receiptService,
  });

  final CartService? cartService;
  final ReceiptService? receiptService;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartService _cartService;
  late final ReceiptService _receiptService;

  CartSnapshot? _cart;
  bool _loading = true;
  bool _generating = false;
  ReceiptLink? _receipt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cartService = widget.cartService ?? CartService();
    _receiptService = widget.receiptService ?? ReceiptService();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await _cartService.fetchCart();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateReceipt() async {
    final cart = _cart;
    if (cart == null || cart.items.isEmpty) return;
    setState(() => _generating = true);
    try {
      final link = await _receiptService.generateReceipt(cart);
      if (!mounted) return;
      setState(() => _receipt = link);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _clearCart() async {
    await _cartService.clearCart();
    setState(() => _receipt = null);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (_cart != null && _cart!.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCart,
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final cart = _cart!;
    if (cart.items.isEmpty) {
      return const Center(
        child: Text('Cart is empty', style: TextStyle(fontSize: 20)),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = cart.items[index];
              return ListTile(
                title: Text(item.label, style: const TextStyle(fontSize: 18)),
                subtitle: Text(
                  '${item.weightKg.toStringAsFixed(3)} kg @ '
                  '\$${item.unitPrice.toStringAsFixed(2)}/kg'
                  '${item.calories > 0 ? ' · ${item.calories.round()} kcal' : ''}',
                ),
                trailing: Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        VerticalDivider(width: 1, color: Colors.grey.shade400),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Subtotal: \$${cart.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Calories: ${cart.totalCalories.round()} kcal',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _generating ? null : _generateReceipt,
                  child: _generating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate receipt'),
                ),
                if (_receipt != null) ...[
                  const SizedBox(height: 24),
                  const Text('Scan for receipt:', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: QrImageView(
                        data: _receipt!.url,
                        version: QrVersions.auto,
                        size: 200,
                      ),
                    ),
                  ),
                  SelectableText(
                    _receipt!.url,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
