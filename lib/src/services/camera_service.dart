import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

class MotionResult {
  final bool detected;
  final double percentage;
  final List<int>? changedPixels;

  MotionResult({required this.detected, required this.percentage, this.changedPixels});
}

class CameraService {
  CameraController? _controller;
  List<int>? _previousFrame;
  Timer? _motionTimer;
  bool _isRecording = false;
  String? _currentVideoPath;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;

  Future<List<CameraDescription>> getCameras() async {
    return await availableCameras();
  }

  Future<void> initializeCamera(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _controller!.initialize();
  }

  Future<CameraImage?> captureFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      return await _controller!.takeFrame();
    } catch (_) {
      return null;
    }
  }

  MotionResult detectMotion(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int totalPixels = width * height;
    final int pixelThreshold = (totalPixels * AppConstants.motionThreshold).toInt();

    final planes = image.planes;
    if (planes.isEmpty) return MotionResult(detected: false, percentage: 0);

    final plane = planes[0];
    final bytes = plane.bytes;

    if (_previousFrame == null || _previousFrame!.length != bytes.length) {
      _previousFrame = bytes.toList();
      return MotionResult(detected: false, percentage: 0);
    }

    int changedPixels = 0;
    const sampleStep = 4;

    for (int i = 0; i < bytes.length; i += sampleStep) {
      final diff = (bytes[i] - _previousFrame![i]).abs();
      if (diff > 30) {
        changedPixels++;
      }
    }

    _previousFrame = bytes.toList();

    final double percentage = changedPixels / (totalPixels / sampleStep);
    return MotionResult(
      detected: percentage > AppConstants.motionThreshold,
      percentage: percentage,
    );
  }

  Future<String?> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_isRecording) return null;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentVideoPath = '${dir.path}/motion_$timestamp.mp4';

    await _controller!.startVideoRecording();
    _isRecording = true;

    Future.delayed(Duration(seconds: AppConstants.videoClipDurationSeconds), () {
      if (_isRecording) stopRecording();
    });

    return _currentVideoPath;
  }

  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) return null;
    _isRecording = false;
    final file = await _controller!.stopVideoRecording();
    return file.path;
  }

  Future<void> startMotionDetection({
    required Function(MotionResult) onMotion,
    required Function(String) onMotionStart,
  }) async {
    _motionTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.motionCheckIntervalMs),
      (timer) async {
        final frame = await captureFrame();
        if (frame == null) return;

        final result = detectMotion(frame);
        if (result.detected) {
          onMotion(result);
          final videoPath = await startRecording();
          if (videoPath != null) {
            onMotionStart(videoPath);
          }
        }
      },
    );
  }

  void stopMotionDetection() {
    _motionTimer?.cancel();
    _motionTimer = null;
  }

  Future<Uint8List?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    final file = await _controller!.takePicture();
    return await file.readAsBytes();
  }

  void dispose() {
    stopMotionDetection();
    _controller?.dispose();
    _controller = null;
  }
}
