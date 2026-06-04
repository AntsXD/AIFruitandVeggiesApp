/// Central configuration — change [backendBaseUrl] for your LAN IP.
class AppConfig {
  static const String backendBaseUrl = 'http://10.0.2.2:8000';

  /// Cart session id for this tablet instance.
  static const String sessionId = 'tablet-1';

  /// How often to poll weight while waiting on confirmed screen.
  static const Duration weightPollInterval = Duration(milliseconds: 500);

  /// Weight readings must match within this tolerance (kg) to count as stable.
  static const double weightStableToleranceKg = 0.002;

  /// Consecutive stable readings required before accepting weight.
  static const int weightStableReadingsRequired = 3;

  static const int inputSize = 224;
  static const String modelAsset = 'assets/model.tflite';
  static const String labelsAsset = 'assets/labels.txt';
}
