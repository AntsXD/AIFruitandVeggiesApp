import '../config/app_config.dart';
import 'weight_store.dart';

/// Reads weight from the in-app [WeightStore] (fed by [EspWebSocketServer]).
class WeightService {
  Future<double> fetchCurrentWeightKg() async {
    return WeightStore.instance.latestWeightKg;
  }

  /// Waits until weight is non-zero and stable for [AppConfig.weightStableReadingsRequired].
  Future<double> waitForStableWeight({
    void Function(double? latest)? onUpdate,
  }) async {
    final readings = <double>[];
    while (true) {
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
