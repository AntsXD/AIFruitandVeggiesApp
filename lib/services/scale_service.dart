import 'dart:developer' as developer;

/// Abstraction for sending a confirmed item label to the physical scale layer.
abstract class ScaleService {
  Future<bool> connect();
  Future<void> sendItem(String label);
}

/// Logs label transport until real hardware transport is wired in.
class MockScaleService implements ScaleService {
  @override
  Future<bool> connect() async {
    developer.log('MockScaleService: connected', name: 'ScaleService');
    return true;
  }

  @override
  Future<void> sendItem(String label) async {
    developer.log('MockScaleService: sendItem($label)', name: 'ScaleService');
  }
}
