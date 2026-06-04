import 'package:flutter/material.dart';

import '../services/inference_service.dart';
import '../services/scale_service.dart';
import 'confirmed_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.predictions,
    required this.onRetake,
    this.scaleService,
  });

  final List<Prediction> predictions;
  final VoidCallback onRetake;
  final ScaleService? scaleService;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<Prediction> _remaining;
  late final ScaleService _scaleService;

  @override
  void initState() {
    super.initState();
    _remaining = List<Prediction>.from(widget.predictions);
    _scaleService = widget.scaleService ?? MockScaleService();
    _scaleService.connect();
  }

  Future<void> _confirm() async {
    if (_remaining.isEmpty) return;
    final top = _remaining.first;
    await _scaleService.sendItem(top.label);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmedScreen(label: top.label),
      ),
    );
  }

  void _reject() {
    if (_remaining.isEmpty) return;
    setState(() => _remaining.removeAt(0));
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Couldn't identify this item",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: widget.onRetake,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final top = _remaining.first;
    final confidence = (top.confidence * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(title: const Text('Is this correct?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      top.label,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${confidence.toStringAsFixed(1)}% confidence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_remaining.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_remaining.length - 1} more suggestion(s) if you reject',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: _confirm,
                    child: const Text('Confirm', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: _reject,
                    child: const Text('Reject', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
