import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/image_picker_adapter.dart';
import 'package:my_sweet_home/features/ocr/data/adapters/image_quality_checker.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_picker_port.dart';
import 'package:my_sweet_home/features/ocr/domain/ports/image_quality_port.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/framing_guide_overlay.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/quality_warning_dialog.dart';
import 'package:my_sweet_home/features/ocr/presentation/widgets/live_camera_preview.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_benchmark_page.dart';

/// Receipt capture screen with framing guide, gallery option
/// and manual entry as accessibility alternative (RF-040, RN-204, A11Y-10).
class OcrCaptureScreen extends StatefulWidget {
  final ImagePickerPort? imagePickerPort;
  final ImageQualityPort? imageQualityPort;
  final Widget? cameraPreview;
  final void Function(String path)? onImageCaptured;
  final VoidCallback? onManualEntry;

  const OcrCaptureScreen({
    super.key,
    this.imagePickerPort,
    this.imageQualityPort,
    this.cameraPreview,
    this.onImageCaptured,
    this.onManualEntry,
  });

  @override
  State<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends State<OcrCaptureScreen> {
  late final ImagePickerPort _imagePicker;
  late final ImageQualityPort _qualityChecker;

  bool _isFlashOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePickerPort ?? ImagePickerAdapter();
    _qualityChecker = widget.imageQualityPort ?? const ImageQualityChecker();
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _previewKey.currentState?.setFlashMode(_isFlashOn);
  }

  Future<void> _handleImageSelected(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final file = File(imagePath);
      final bytes = file.existsSync() ? await file.readAsBytes() : Uint8List(0);
      final report = await _qualityChecker.assess(bytes);

      if (!mounted) return;

      if (!report.isAcceptable) {
        setState(() {
          _isProcessing = false;
        });

        await QualityWarningDialog.show(
          context: context,
          report: report,
          onRetake: () {
            // Permanece na tela para nova foto
          },
          onContinue: () {
            widget.onImageCaptured?.call(imagePath);
          },
        );
        return;
      }

      if (!mounted) return;
      widget.onImageCaptured?.call(imagePath);
    } catch (e) {
      if (!mounted) return;
      widget.onImageCaptured?.call(imagePath);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  final _previewKey = GlobalKey<LiveCameraPreviewState>();

  Future<void> _captureFromCamera() async {
    if (_isProcessing) return;
    String? path;
    if (widget.cameraPreview == null) {
      path = await _previewKey.currentState?.takePicture();
    } else {
      path = await _imagePicker.captureFromCamera();
    }

    if (path != null && mounted) {
      await _handleImageSelected(path);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    final path = await _imagePicker.pickFromGallery();
    if (path != null && mounted) {
      await _handleImageSelected(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back, color: Colors.white),
          tooltip: 'Voltar',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Escanear nota fiscal',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? AppIcons.flashOn : AppIcons.flashOff,
              color: _isFlashOn ? Colors.yellow : Colors.white,
            ),
            tooltip: _isFlashOn ? 'Desativar flash' : 'Ativar flash',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(AppIcons.priceHistory, color: Colors.white),
            tooltip: 'Benchmark de Precisão OCR',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const OcrBenchmarkPage()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Viewport (Preview or synthetic Placeholder for tests/emulator)
          Positioned.fill(
            child: widget.cameraPreview ?? LiveCameraPreview(key: _previewKey),
          ),

          // Guia de enquadramento (RF-040, A11Y-10)
          const Positioned.fill(child: FramingGuideOverlay()),

          // Indicador de progresso se estiver avaliando imagem
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Avaliando qualidade da imagem...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls bar with accessibility options (A11Y-10)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 24.0,
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Button to select from gallery (A11Y-10)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            AppIcons.gallery,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Escolher foto da galeria',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _isProcessing ? null : _pickFromGallery,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Galeria',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),

                    // Central photo capture button (RF-040)
                    Semantics(
                      label: 'Tirar foto da nota fiscal',
                      button: true,
                      child: InkWell(
                        onTap: _isProcessing ? null : _captureFromCamera,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.white24,
                          ),
                          child: const Icon(
                            AppIcons.camera,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    // Manual entry button (A11Y-10)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            AppIcons.edit,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Lançar manualmente',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : widget.onManualEntry,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manual',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
