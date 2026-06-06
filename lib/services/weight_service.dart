import 'dart:async';

import '../config/app_config.dart';
import 'weight_store.dart';

class WeightTimeoutException implements Exception {
  final String message;
  WeightTimeoutException([this.message = 'Timed out waiting for stable weight']);

  @override
  String toString() => 'WeightTimeoutException: $message';
}

class WeightService {
  Future<double> fetchCurrentWeightKg() async {
    return WeightStore.instance.latestWeightKg;
  }

  Future<double> waitForStableWeight({
    void Function(double? latest)? onUpdate,
    Duration? timeout,
  }) async {
    final deadline = DateTime.now().add(timeout ?? AppConfig.weightTimeout);
    final readings = <double>[];
    while (true) {
      if (DateTime.now().isAfter(deadline)) {
        throw WeightTimeoutException();
      }
      await Future<void>.delayed(AppConfig.weightPollInterval);
      final weight = await fetchCurrentWeightKg();
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
