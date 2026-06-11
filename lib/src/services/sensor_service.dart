import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants.dart';

final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

class EarthquakeResult {
  final bool detected;
  final String phase; // 'p_wave', 's_wave', 'none'
  final double magnitude;
  final DateTime timestamp;

  EarthquakeResult({
    required this.detected,
    this.phase = 'none',
    this.magnitude = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class FloodResult {
  final bool detected;
  final double orientationChange;
  final double waterSoundConfidence;
  final String location;

  FloodResult({
    required this.detected,
    this.orientationChange = 0,
    this.waterSoundConfidence = 0,
    this.location = '',
  });
}

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  List<double> _accelHistory = [];
  bool _isMonitoring = false;
  double _baselineOrientation = 0;

  bool get isMonitoring => _isMonitoring;

  // Earthquake detection
  final List<double> _pWaveBuffer = [];
  Timer? _earthquakeTimer;

  Future<void> startEarthquakeMonitoring({
    required Function(EarthquakeResult) onPWave,
    required Function(EarthquakeResult) onSWave,
  }) async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: (1000 / AppConstants.accelerometerSampleRateHz).round()),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Normalize to g-force
      final gForce = magnitude / 9.81;
      _accelHistory.add(gForce);
      if (_accelHistory.length > 100) {
        _accelHistory.removeAt(0);
      }

      // P-wave detection: lateral accel between 0.2g and 0.5g, 0.5-2s duration
      if (gForce >= AppConstants.earthquakePWaveMinG &&
          gForce <= AppConstants.earthquakePWaveMaxG) {
        _pWaveBuffer.add(DateTime.now().millisecondsSinceEpoch.toDouble());
        if (_pWaveBuffer.length > 1) {
          final duration = _pWaveBuffer.last - _pWaveBuffer.first;
          if (duration >= 500 && duration <= 2000 && _pWaveBuffer.length >= 10) {
            // Check for decay pattern (earthquake) vs sharp spike (human)
            final isEarthquake = _checkDecayPattern();
            if (isEarthquake) {
              onPWave(EarthquakeResult(
                detected: true,
                phase: 'p_wave',
                magnitude: gForce,
              ));
            }
          }
        }
      } else {
        if (_pWaveBuffer.isNotEmpty &&
            DateTime.now().millisecondsSinceEpoch - _pWaveBuffer.last > 3000) {
          _pWaveBuffer.clear();
        }
      }
    });
  }

  bool _checkDecayPattern() {
    // Earthquake: repeated oscillations with decaying amplitude
    // Human: single sharp spike
    if (_accelHistory.length < 20) return false;

    int zeroCrossings = 0;
    for (int i = 1; i < _accelHistory.length; i++) {
      if ((_accelHistory[i - 1] > 1.0 && _accelHistory[i] <= 1.0) ||
          (_accelHistory[i - 1] < 1.0 && _accelHistory[i] >= 1.0)) {
        zeroCrossings++;
      }
    }

    // Earthquake should have multiple oscillations
    return zeroCrossings >= 3;
  }

  // Flood detection - orientation monitoring
  Future<void> startFloodMonitoring({
    required Function(FloodResult) onFloodDetected,
  }) async {
    // Get baseline orientation when placed face-down
    final event = await accelerometerEventStream().first;
    _baselineOrientation = atan2(event.y, event.x);

    accelerometerEventStream().listen((event) {
      final currentOrientation = atan2(event.y, event.x);
      final orientationChange = (currentOrientation - _baselineOrientation).abs() * 180 / pi;

      if (orientationChange > AppConstants.floodOrientationThreshold) {
        onFloodDetected(FloodResult(
          detected: true,
          orientationChange: orientationChange,
        ));
      }
    });
  }

  Stopwatch? _continuousVibrationTimer;

  void checkContinuousVibration({
    required Function() onSustained,
  }) {
    final recent = _accelHistory.where((a) => a > 0.05).toList();
    if (recent.length > _accelHistory.length * 0.5) {
      // Sustained vibration for >5 seconds
      _continuousVibrationTimer ??= Stopwatch()..start();
      if (_continuousVibrationTimer!.elapsedSeconds > 5) {
        onSustained();
        _continuousVibrationTimer?.reset();
      }
    } else {
      _continuousVibrationTimer?.reset();
      _continuousVibrationTimer = null;
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _accelHistory.clear();
    _pWaveBuffer.clear();
  }

  void dispose() {
    stopMonitoring();
  }
}
