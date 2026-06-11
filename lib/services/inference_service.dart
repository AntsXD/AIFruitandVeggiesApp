import 'dart:developer' as developer;
import 'dart:math' show exp;

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

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    print('MODEL input shape: ${inputTensor.shape}, type: ${inputTensor.type}');
    print('MODEL output shape: ${outputTensor.shape}, type: ${outputTensor.type}');
    print('MODEL labels count: ${_labels.length}');
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
    return _runInference(_preprocess(decoded));
  }

  Future<List<Prediction>> predictFromImage(img.Image image) async {
    await load();
    return _runInference(_preprocess(image));
  }

  List<Prediction> _runInference(List<List<List<List<double>>>> input) {
    final outputCount = _labels.length;
    final output = List.generate(1, (_) => List.filled(outputCount, 0.0));
    _interpreter!.run(input, output);

    final scores = output.first;
    final topScores = <MapEntry<int, double>>[];
    for (var i = 0; i < scores.length; i++) {
      topScores.add(MapEntry(i, scores[i]));
    }
    topScores.sort((a, b) => b.value.compareTo(a.value));
    developer.log('Top 5 raw logits: ${topScores.take(5).map((e) => "${_labels[e.key]}=${e.value.toStringAsFixed(4)}")}', name: 'Inference');

    final probs = _softmax(scores);
    final topProbs = <MapEntry<int, double>>[];
    for (var i = 0; i < probs.length; i++) {
      topProbs.add(MapEntry(i, probs[i]));
    }
    topProbs.sort((a, b) => b.value.compareTo(a.value));
    print('TOP 5 probs: ${topProbs.take(5).map((e) => "${_labels[e.key]}=${(e.value * 100).toStringAsFixed(1)}%")}');

    return _processOutput(probs);
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  List<Prediction> _processOutput(List<double> scores) {
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

    final p0 = resized.getPixel(0, 0);
    final p64 = resized.getPixel(64, 64);
    print('IMAGE decoded: ${image.width}x${image.height}, cropped: ${size}x${size}');
    print('PIXEL (0,0) r=${p0.r} g=${p0.g} b=${p0.b} a=${p0.a}');
    print('PIXEL (64,64) r=${p64.r} g=${p64.g} b=${p64.b} a=${p64.a}');
    print('NORM (0,0) raw: ${p0.r.toDouble()}, g: ${p0.g.toDouble()}, b: ${p0.b.toDouble()}');

    return [
      List.generate(
        AppConfig.inputSize,
        (y) => List.generate(
          AppConfig.inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r.toDouble(),
              pixel.g.toDouble(),
              pixel.b.toDouble(),
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
