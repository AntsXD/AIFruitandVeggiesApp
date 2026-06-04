import 'package:flutter/foundation.dart';

/// In-memory latest weight from the ESP32 WebSocket connection.
class WeightStore extends ChangeNotifier {
  WeightStore._();
  static final WeightStore instance = WeightStore._();

  double _weightKg = 0.0;
  DateTime? _updatedAt;
  bool _espConnected = false;

  double get latestWeightKg => _weightKg;
  DateTime? get updatedAt => _updatedAt;
  bool get espConnected => _espConnected;

  void setConnected(bool connected) {
    if (_espConnected == connected) return;
    _espConnected = connected;
    notifyListeners();
  }

  void updateWeight(double weightKg) {
    _weightKg = weightKg;
    _updatedAt = DateTime.now();
    notifyListeners();
  }

  void reset() {
    _weightKg = 0.0;
    _updatedAt = null;
    notifyListeners();
  }
}
