import 'package:flutter/material.dart';

import '../services/calorie_service.dart';
import '../services/cart_service.dart';
import '../services/price_service.dart';
import '../services/weight_service.dart';

class ConfirmedScreen extends StatefulWidget {
  const ConfirmedScreen({
    super.key,
    required this.label,
    this.weightService,
    this.priceService,
    this.calorieService,
    this.cartService,
  });

  final String label;
  final WeightService? weightService;
  final PriceService? priceService;
  final CalorieService? calorieService;
  final CartService? cartService;

  @override
  State<ConfirmedScreen> createState() => _ConfirmedScreenState();
}

class _ConfirmedScreenState extends State<ConfirmedScreen> {
  late final WeightService _weightService;
  late final PriceService _priceService;
  late final CalorieService _calorieService;
  late final CartService _cartService;

  bool _loading = true;
  String? _error;
  double? _weightKg;
  double? _unitPrice;
  double? _lineTotal;
  double? _calories;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _weightService = widget.weightService ?? WeightService();
    _priceService = widget.priceService ?? PriceService();
    _calorieService = widget.calorieService ?? const CalorieService();
    _cartService = widget.cartService ?? CartService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final price = await _priceService.fetchPrice(widget.label);
      final calInfo = await _calorieService.fetchCalories(widget.label);
      final weight = await _weightService.waitForStableWeight(
        onUpdate: (w) {
          if (mounted) setState(() => _weightKg = w);
        },
      );
      final total = weight * price.pricePerKg;
      if (!mounted) return;
      setState(() {
        _weightKg = weight;
        _unitPrice = price.pricePerKg;
        _lineTotal = total;
        _calories = weight * 10 * calInfo.kcalPer100g;
        _loading = false;
      });
    } on WeightTimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'Timed out waiting for stable weight.\nMake sure the scale is connected and place the item on it.';
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

  Future<void> _addToCart() async {
    final weight = _weightKg;
    final unit = _unitPrice;
    final total = _lineTotal;
    final calories = _calories;
    if (weight == null || unit == null || total == null) return;
    setState(() => _adding = true);
    try {
      await _cartService.addItem(
        label: widget.label,
        weightKg: weight,
        unitPrice: unit,
        total: total,
        calories: calories ?? 0,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _weightKg == null
                          ? 'Waiting for stable weight on scale…'
                          : 'Stabilizing weight (${_weightKg!.toStringAsFixed(1)} kg)…',
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _buildSummary(),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _row('Weight', '${_weightKg!.toStringAsFixed(3)} kg'),
        _row('Calories', '~${_calories!.round()} kcal'),
        _row('Unit price', '\$${_unitPrice!.toStringAsFixed(2)} / kg'),
        _row('Line total', '\$${_lineTotal!.toStringAsFixed(2)}',
            bold: true),
        const Spacer(),
        FilledButton(
          onPressed: _adding ? null : _addToCart,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(20)),
          child: _adding
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add to cart', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(20)),
          child: const Text('Retake', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
