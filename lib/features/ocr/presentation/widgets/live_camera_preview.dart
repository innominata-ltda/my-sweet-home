import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveCameraPreview extends StatefulWidget {
  const LiveCameraPreview({super.key});

  @override
  State<LiveCameraPreview> createState() => LiveCameraPreviewState();
}

class LiveCameraPreviewState extends State<LiveCameraPreview> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await _controller!.initialize();
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (_) {
        // Some devices do not support manual focus/exposure mode adjustment
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Ignore camera initialization errors in production.
    }
  }

  Future<void> setFlashMode(bool enabled) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _controller!.setFlashMode(
        enabled ? FlashMode.torch : FlashMode.off,
      );
    } catch (_) {
      // Ignore if device does not have flash
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;
    try {
      final file = await _controller!.takePicture();
      return file.path;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }
    return CameraPreview(_controller!);
  }
}
