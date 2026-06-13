import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../config/app_config.dart';
import 'receipt_service.dart';
import 'weight_store.dart';

class EspWebSocketServer {
  EspWebSocketServer._();
  static final EspWebSocketServer instance = EspWebSocketServer._();

  HttpServer? _server;
  final Set<WebSocket> _clients = {};
  bool _running = false;
  RawDatagramSocket? _udpSocket;
  Timer? _discoveryTimer;

  bool get isRunning => _running;
  int get port => AppConfig.espWebSocketPort;
  int get connectedClients => _clients.length;

  Future<void> start() async {
    if (_running) return;
    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        AppConfig.espWebSocketPort,
      );
      _running = true;
      developer.log(
        'ESP WebSocket server on port $port (path ${AppConfig.espWebSocketPath})',
        name: 'EspWebSocketServer',
      );
    } catch (e, st) {
      developer.log('Failed to bind WebSocket server on port $port: $e',
          name: 'EspWebSocketServer', error: e, stackTrace: st);
      return;
    }

    unawaited(_server!.forEach(_handleRequest));
    _startDiscovery();
  }

  void _startDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final message = utf8.encode('JSR241 ${AppConfig.espWebSocketPort}');
      _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _udpSocket!.send(
          message,
          InternetAddress('192.168.4.1'),
          AppConfig.espDiscoveryPort,
        );
      });
      developer.log(
        'UDP discovery: sending "JSR241 ${AppConfig.espWebSocketPort}" to '
        '192.168.4.1:${AppConfig.espDiscoveryPort} every 2s',
        name: 'EspWebSocketServer',
      );
    } catch (e) {
      developer.log('UDP discovery failed: $e', name: 'EspWebSocketServer');
    }
  }

  Future<void> stop() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
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

    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return;
    }

    if (path == AppConfig.espWebSocketPath ||
        path == '${AppConfig.espWebSocketPath}/') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _onClientConnected(socket);
        return;
      }
    }

    if (path.startsWith('/receipt/')) {
      final token = path.substring('/receipt/'.length);
      final receipt = ReceiptService.getReceipt(token);
      if (receipt == null) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': 'Receipt not found'}))
          ..close();
        return;
      }
      final accept = request.headers.value('accept') ?? '';
      if (accept.contains('json')) {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(receipt))
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(ReceiptService.buildReceiptHtml(receipt))
          ..close();
      }
      return;
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
      if (json is! Map<String, dynamic>) return;

      final kg = json['kg'];
      if (kg == null) return;

      final weightKg = (kg as num).toDouble();
      WeightStore.instance.updateWeight(weightKg);
    } catch (e) {
      developer.log('Bad message: $e', name: 'EspWebSocketServer');
    }
  }
}
