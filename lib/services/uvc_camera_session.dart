import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uvccamera/uvccamera.dart';

/// Manages attach → USB permission → [UvcCameraController] for one UVC device.
class UvcCameraSession {
  UvcCameraSession({required this.onStateChanged});

  final VoidCallback onStateChanged;

  UvcCameraDevice? device;
  UvcCameraController? controller;
  Future<void>? initializeFuture;

  StreamSubscription<UvcCameraDeviceEvent>? _deviceSub;
  StreamSubscription<UvcCameraErrorEvent>? _errorSub;

  bool isAttached = false;
  bool isConnected = false;
  bool hasCameraPermission = false;
  bool hasDevicePermission = false;
  String? lastError;

  bool get isReady =>
      controller != null && controller!.value.isInitialized && isConnected;

  Future<bool> tryStart() async {
    lastError = null;
    final supported = await UvcCamera.isSupported();
    if (!supported) {
      lastError = 'USB host not supported on this device';
      return false;
    }

    final devices = await UvcCamera.getDevices();
    if (devices.isEmpty) {
      lastError = 'No USB camera detected — plug in the camera';
      return false;
    }

    device = devices.values.first;
    _listenDeviceEvents();
    onStateChanged();

    if (devices.containsKey(device!.name)) {
      isAttached = true;
      onStateChanged();
      await _requestPermissions();
    }
    return isReady;
  }

  void _listenDeviceEvents() {
    _deviceSub?.cancel();
    _deviceSub = UvcCamera.deviceEventStream.listen((event) {
      if (device == null || event.device.name != device!.name) return;

      switch (event.type) {
        case UvcCameraDeviceEventType.attached:
          isAttached = true;
          _requestPermissions();
        case UvcCameraDeviceEventType.detached:
          _tearDownController();
          isAttached = false;
          isConnected = false;
          hasCameraPermission = false;
          hasDevicePermission = false;
        case UvcCameraDeviceEventType.connected:
          hasCameraPermission = true;
          hasDevicePermission = true;
          isAttached = true;
          isConnected = true;
          _openController();
        case UvcCameraDeviceEventType.disconnected:
          _tearDownController();
          isConnected = false;
          hasDevicePermission = false;
      }
      onStateChanged();
    });
  }

  Future<void> _requestPermissions() async {
    final cam = await Permission.camera.request();
    hasCameraPermission = cam.isGranted;
    onStateChanged();
    if (!hasCameraPermission) {
      lastError = 'Camera permission required for USB camera';
      return;
    }
    if (device != null) {
      hasDevicePermission =
          await UvcCamera.requestDevicePermission(device!);
      onStateChanged();
      if (!hasDevicePermission) {
        lastError = 'Allow USB access when prompted';
      }
    }
  }

  void _openController() {
    if (device == null || controller != null) return;
    controller = UvcCameraController(device: device!);
    initializeFuture = controller!.initialize().then((_) {
      _errorSub = controller!.cameraErrorEvents.listen((event) {
        if (event.error.type == UvcCameraErrorType.previewInterrupted) {
          _tearDownController();
          isConnected = false;
          onStateChanged();
          _requestPermissions();
        }
      });
      onStateChanged();
    });
  }

  void _tearDownController() {
    _errorSub?.cancel();
    _errorSub = null;
    controller?.dispose();
    controller = null;
    initializeFuture = null;
  }

  Future<void> dispose() async {
    _deviceSub?.cancel();
    _deviceSub = null;
    _tearDownController();
    device = null;
  }
}
