import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';

import '../config/app_config.dart';
import '../services/inference_service.dart';
import '../services/weight_store.dart';
import '../services/uvc_camera_session.dart';
import '../widgets/camera_overlay.dart';
import 'result_screen.dart';

enum _CameraSource { none, usb, builtin }

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.inferenceService,
    required this.onOpenCart,
  });

  final InferenceService inferenceService;
  final VoidCallback onOpenCart;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  _CameraSource _source = _CameraSource.none;
  bool _initializing = true;
  bool _capturing = false;
  String? _error;

  CameraController? _builtinController;
  late final UvcCameraSession _uvcSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uvcSession = UvcCameraSession(onStateChanged: () {
      if (mounted) setState(() {});
    });
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _source == _CameraSource.usb) {
      _initCamera();
    } else if (state == AppLifecycleState.paused && _source == _CameraSource.usb) {
      unawaited(_uvcSession.dispose());
      setState(() => _source = _CameraSource.none);
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
      _source = _CameraSource.none;
    });

    await _builtinController?.dispose();
    _builtinController = null;
    await _uvcSession.dispose();

    final uvcStarted = await _uvcSession.tryStart();
    if (!mounted) return;

    if (uvcStarted && _uvcSession.isReady) {
      setState(() {
        _source = _CameraSource.usb;
        _initializing = false;
      });
      return;
    }

    // USB camera plugged in but still waiting for permission / connection
    if (_uvcSession.device != null && _uvcSession.isAttached) {
      setState(() {
        _source = _CameraSource.usb;
        _initializing = false;
        _error = _uvcSession.lastError;
      });
      return;
    }

    await _initBuiltinCamera();
  }

  Future<void> _initBuiltinCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      setState(() {
        _error = 'Camera permission denied';
        _initializing = false;
        _source = _CameraSource.none;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = _uvcSession.lastError ?? 'No camera found';
          _initializing = false;
        });
        return;
      }
      final camera = _pickCamera(cameras);
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _builtinController = controller;
        _source = _CameraSource.builtin;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Camera init failed: $e';
        _initializing = false;
      });
    }
  }

  CameraDescription _pickCamera(List<CameraDescription> cameras) {
    final back =
        cameras.where((c) => c.lensDirection == CameraLensDirection.back);
    if (back.isNotEmpty) return back.first;
    return cameras.first;
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = switch (_source) {
        _CameraSource.usb => await _captureUvc(),
        _CameraSource.builtin => await _captureBuiltin(),
        _ => throw Exception('Camera not ready'),
      };
      final predictions =
          await widget.inferenceService.predict(Uint8List.fromList(bytes));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            predictions: predictions,
            onRetake: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<List<int>> _captureBuiltin() async {
    final controller = _builtinController;
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Built-in camera not ready');
    }
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  Future<List<int>> _captureUvc() async {
    final controller = _uvcSession.controller;
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('USB camera not ready — check cable and USB permission');
    }
    final file = await controller.takePicture();
    return file.readAsBytes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _builtinController?.dispose();
    unawaited(_uvcSession.dispose());
    super.dispose();
  }

  Widget _statusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  String get _sourceLabel {
    return switch (_source) {
      _CameraSource.usb => 'USB camera',
      _CameraSource.builtin => 'Built-in camera',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(child: CircularProgressIndicator())
          else
            _buildPreview(),
          const CameraOverlay(),
          if (!_initializing)
            Positioned(
              top: 16,
              left: 16,
              child: ListenableBuilder(
                listenable: WeightStore.instance,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_sourceLabel.isNotEmpty) _statusChip(_sourceLabel),
                    const SizedBox(height: 6),
                    _statusChip(
                      WeightStore.instance.espConnected
                          ? 'ESP connected :${AppConfig.espWebSocketPort}'
                          : 'ESP waiting ws://*:${AppConfig.espWebSocketPort}${AppConfig.espWebSocketPath}',
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 32),
              onPressed: widget.onOpenCart,
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: (_capturing || !_canCapture) ? null : _capture,
                child: _capturing
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canCapture {
    if (_source == _CameraSource.builtin) {
      return _builtinController?.value.isInitialized ?? false;
    }
    if (_source == _CameraSource.usb) {
      return _uvcSession.isReady;
    }
    return false;
  }

  Widget _buildPreview() {
    if (_error != null && _source != _CameraSource.usb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return switch (_source) {
      _CameraSource.builtin when _builtinController != null =>
        CameraPreview(_builtinController!),
      _CameraSource.usb => _buildUvcPreview(),
      _ => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? _uvcSession.lastError ?? 'No camera available',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    };
  }

  Widget _buildUvcPreview() {
    if (!_uvcSession.isConnected || _uvcSession.controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _uvcSession.lastError ??
                    'USB camera detected — allow USB permission when prompted',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (_uvcSession.device != null) ...[
                const SizedBox(height: 8),
                Text(
                  _uvcSession.device!.name,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _uvcSession.initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'USB camera error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        final controller = _uvcSession.controller!;
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            child: UvcCameraPreview(controller),
          ),
        );
      },
    );
  }
}
