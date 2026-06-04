import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../config/app_config.dart';
import 'weight_store.dart';

/// Small WebSocket server on the tablet — ESP32 connects over WiFi and pushes weight.
class EspWebSocketServer {
  EspWebSocketServer._();
  static final EspWebSocketServer instance = EspWebSocketServer._();

  HttpServer? _server;
  final Set<WebSocket> _clients = {};
  bool _running = false;

  bool get isRunning => _running;
  int get port => AppConfig.espWebSocketPort;
  int get connectedClients => _clients.length;

  /// Starts listening on all interfaces (`0.0.0.0:[port]`).
  Future<void> start() async {
    if (_running) return;
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      AppConfig.espWebSocketPort,
    );
    _running = true;
    developer.log(
      'ESP WebSocket server on port $port (path ${AppConfig.espWebSocketPath})',
      name: 'EspWebSocketServer',
    );

    unawaited(_server!.forEach(_handleRequest));
  }

  Future<void> stop() async {
    for (final client in _clients.toList()) {
      await client.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _running = false;
    WeightStore.instance.setConnected(false);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (path == AppConfig.espWebSocketPath ||
        path == '${AppConfig.espWebSocketPath}/') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _onClientConnected(socket);
        return;
      }
    }

    if (path == '/' || path.isEmpty) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write(
          'Produce classifier — ESP WebSocket at '
          'ws://<tablet-ip>:$port${AppConfig.espWebSocketPath}',
        )
        ..close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }

  void _onClientConnected(WebSocket socket) {
    _clients.add(socket);
    WeightStore.instance.setConnected(true);
    developer.log('ESP connected (${_clients.length} client(s))',
        name: 'EspWebSocketServer');

    socket.listen(
      (dynamic message) => _onMessage(socket, message),
      onDone: () => _onClientDisconnected(socket),
      onError: (_) => _onClientDisconnected(socket),
      cancelOnError: true,
    );

    socket.add(jsonEncode({'type': 'welcome', 'ok': true}));
  }

  void _onClientDisconnected(WebSocket socket) {
    _clients.remove(socket);
    if (_clients.isEmpty) {
      WeightStore.instance.setConnected(false);
    }
    developer.log('ESP disconnected (${_clients.length} client(s) left)',
        name: 'EspWebSocketServer');
  }

  void _onMessage(WebSocket socket, dynamic message) {
    try {
      final text = message is String ? message : utf8.decode(message as List<int>);
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) {
        _sendError(socket, 'Expected JSON object');
        return;
      }

      final weight = json['weight_kg'];
      if (weight == null) {
        _sendError(socket, 'Missing weight_kg');
        return;
      }

      final weightKg = (weight as num).toDouble();
      WeightStore.instance.updateWeight(weightKg);

      socket.add(jsonEncode({
        'ok': true,
        'weight_kg': weightKg,
      }));
    } catch (e) {
      developer.log('Bad message: $e', name: 'EspWebSocketServer');
      _sendError(socket, 'Invalid message: $e');
    }
  }

  void _sendError(WebSocket socket, String detail) {
    socket.add(jsonEncode({'ok': false, 'error': detail}));
  }
}
