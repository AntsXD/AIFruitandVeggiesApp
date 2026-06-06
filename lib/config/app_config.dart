/// App configuration.
class AppConfig {
  /// WebSocket port the ESP32 connects to (tablet must be on same WiFi).
  static const int espWebSocketPort = 8765;

  /// WebSocket path — full URL: `ws://<tablet-ip>:8765/esp`
  static const String espWebSocketPath = '/ws';

  static const int espDiscoveryPort = 49500;
  static const String espSsid = 'ScaleEasy';

  /// Cart session id (used when step-2 local cart is wired up).
  static const String sessionId = 'tablet-1';



  static const Duration weightPollInterval = Duration(milliseconds: 500);
  static const Duration weightTimeout = Duration(seconds: 60);
  static const double weightStableToleranceKg = 0.002;
  static const int weightStableReadingsRequired = 3;

  static const int inputSize = 128;
  static const String modelAsset = 'assets/model.tflite';
  static const String labelsAsset = 'assets/labels.txt';
}
