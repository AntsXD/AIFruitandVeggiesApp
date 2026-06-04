import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class WeightService {
  WeightService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<double> fetchCurrentWeightKg() async {
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/weight/current');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weight fetch failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['weight_kg'] as num).toDouble();
  }

  /// Poll until weight is non-zero and stable for [AppConfig.weightStableReadingsRequired].
  Future<double> waitForStableWeight({
    void Function(double? latest)? onUpdate,
  }) async {
    final readings = <double>[];
    while (true) {
      await Future<void>.delayed(AppConfig.weightPollInterval);
      double weight;
      try {
        weight = await fetchCurrentWeightKg();
      } catch (_) {
        onUpdate?.call(null);
        continue;
      }
      onUpdate?.call(weight);
      if (weight <= 0) {
        readings.clear();
        continue;
      }
      readings.add(weight);
      if (readings.length > AppConfig.weightStableReadingsRequired) {
        readings.removeAt(0);
      }
      if (readings.length == AppConfig.weightStableReadingsRequired &&
          _isStable(readings)) {
        return readings.last;
      }
    }
  }

  bool _isStable(List<double> values) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max - min) <= AppConfig.weightStableToleranceKg;
  }
}
