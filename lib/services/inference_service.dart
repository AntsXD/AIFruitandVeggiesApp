import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../config/app_config.dart';

class Prediction {
  Prediction({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class InferenceService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  Future<void> load() async {
    if (_interpreter != null) return;
    _labels = await _loadLabels();
    _interpreter = await Interpreter.fromAsset(AppConfig.modelAsset);
  }

  Future<List<String>> _loadLabels() async {
    final raw = await rootBundle.loadString(AppConfig.labelsAsset);
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Future<List<Prediction>> predict(Uint8List jpegBytes) async {
    await load();
    final decoded = img.decodeImage(jpegBytes);
    if (decoded == null) {
      throw Exception('Could not decode captured image');
    }
    final input = _preprocess(decoded);
    final outputCount = _labels.length;
    final output = List.generate(1, (_) => List.filled(outputCount, 0.0));
    _interpreter!.run(input, output);
    final scores = output.first;
    final merged = <String, double>{};
    for (var i = 0; i < scores.length; i++) {
      final label = _labels[i];
      merged[label] = (merged[label] ?? 0) + scores[i];
    }
    final entries =
        merged.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => Prediction(label: e.key, confidence: e.value))
        .toList();
  }

  List<List<List<List<double>>>> _preprocess(img.Image image) {
    final size = image.width < image.height ? image.width : image.height;
    final left = (image.width - size) ~/ 2;
    final top = (image.height - size) ~/ 2;
    final cropped = img.copyCrop(image, x: left, y: top, width: size, height: size);
    final resized = img.copyResize(
      cropped,
      width: AppConfig.inputSize,
      height: AppConfig.inputSize,
    );
    return [
      List.generate(
        AppConfig.inputSize,
        (y) => List.generate(
          AppConfig.inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    ];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
