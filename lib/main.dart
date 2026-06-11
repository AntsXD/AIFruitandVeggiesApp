import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/camera_screen.dart';
import 'screens/cart_screen.dart';
import 'services/esp_websocket_server.dart';
import 'services/inference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await EspWebSocketServer.instance.start();
  } catch (e, st) {
    developer.log(
      'ESP WebSocket server failed to start: $e',
      name: 'main',
      error: e,
      stackTrace: st,
    );
  }

  runApp(const FruitClassifierApp());
}

class FruitClassifierApp extends StatefulWidget {
  const FruitClassifierApp({super.key});

  @override
  State<FruitClassifierApp> createState() => _FruitClassifierAppState();
}

class _FruitClassifierAppState extends State<FruitClassifierApp> {
  final InferenceService _inferenceService = InferenceService();

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Produce Classifier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: CameraScreen(
        inferenceService: _inferenceService,
        onOpenCart: _openCart,
      ),
    );
  }
}
