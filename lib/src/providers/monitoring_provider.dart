import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
import '../services/camera_service.dart';
import '../services/audio_service.dart';
import '../services/sensor_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/telegram_service.dart';
import '../services/supabase_service.dart';
import 'subscription_provider.dart';

enum MonitoringState { idle, active, alert }

class MonitoringNotifier extends StateNotifier<MonitoringState> {
  final Ref _ref;
  CameraService? _cameraService;
  AudioService? _audioService;
  SensorService? _sensorService;

  bool _isPremium = false;
  bool _isMonitoring = false;

  MonitoringNotifier(this._ref) : super(MonitoringState.idle);

  bool get isMonitoring => _isMonitoring;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    state = MonitoringState.active;

    _isPremium = _ref.read(isPremiumProvider);

    final cameraSvc = _ref.read(cameraServiceProvider);
    final audioSvc = _ref.read(audioServiceProvider);
    final sensorSvc = _ref.read(sensorServiceProvider);

    _cameraService = cameraSvc;
    _audioService = audioSvc;
    _sensorService = sensorSvc;

    // Start motion detection (free tier)
    await cameraSvc.startMotionDetection(
      onMotion: (result) => _handleMotionDetection(result),
      onMotionStart: (path) => _handleMotionAlert(path),
    );

    // Start audio monitoring (premium)
    if (_isPremium) {
      await audioSvc.startListening(
        onAnalysis: (result) => _handleAudioAnalysis(result),
      );

      // Start earthquake monitoring (premium)
      await sensorSvc.startEarthquakeMonitoring(
        onPWave: (result) => _handlePWave(result),
        onSWave: (result) => _handleSWave(result),
      );
    }
  }

  void _handleMotionDetection(MotionResult result) {
    // Motion detected - handled via callback
  }

  Future<void> _handleMotionAlert(String videoPath) async {
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: 'local',
      threatType: ThreatType.intruder,
      confidence: 0.9,
      mediaUrl: videoPath,
    );

    // Save locally
    final storageSvc = _ref.read(storageServiceProvider);
    final cloudUrl = await storageSvc.uploadToCloud(videoPath, 'local');

    // Notify
    final notifSvc = _ref.read(notificationServiceProvider);
    await notifSvc.showLocalNotification(
      id: DateTime.now().millisecond,
      title: 'Intruder Detected',
      body: 'Motion detected with ${alert.confidenceLabel} confidence',
    );

    // Send to Telegram if configured
    final telegramSvc = _ref.read(telegramServiceProvider);
    // telegramSvc.sendAlert(...)

    // Add to alert list
    final alertNotifier = _ref.read(alertProvider.notifier);
    final updatedAlert = cloudUrl != null
        ? Alert(
            id: alert.id,
            deviceId: alert.deviceId,
            threatType: alert.threatType,
            confidence: alert.confidence,
            mediaUrl: cloudUrl,
          )
        : alert;
    await alertNotifier.addAlert(updatedAlert);

    state = MonitoringState.alert;
    Future.delayed(const Duration(seconds: 3), () {
      if (_isMonitoring) state = MonitoringState.active;
    });
  }

  void _handleAudioAnalysis(AudioAnalysisResult result) {
    if (!result.isDetected) return;

    ThreatType threatType;
    switch (result.type) {
      case 'glass':
        threatType = ThreatType.glass;
        break;
      case 'fire_alarm':
        threatType = ThreatType.fire;
        break;
      case 'water':
        threatType = ThreatType.flood;
        break;
      default:
        return;
    }

    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: 'local',
      threatType: threatType,
      confidence: result.confidence,
    );

    _ref.read(alertProvider.notifier).addAlert(alert);
    _ref.read(notificationServiceProvider).showLocalNotification(
      id: DateTime.now().millisecond,
      title: '${threatType.label} Detected',
      body: 'Detected with ${alert.confidenceLabel} confidence',
    );

    state = MonitoringState.alert;
  }

  void _handlePWave(EarthquakeResult result) {
    // 10-second countdown before S-wave
    // Show DUCK, COVER, HOLD screen
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: 'local',
      threatType: ThreatType.earthquake,
      confidence: result.magnitude / 0.5,
    );

    _ref.read(alertProvider.notifier).addAlert(alert);
    state = MonitoringState.alert;
  }

  void _handleSWave(EarthquakeResult result) {
    // S-wave hit - send emergency alert
    _ref.read(notificationServiceProvider).showLocalNotification(
      id: DateTime.now().millisecond,
      title: 'Earthquake S-Wave',
      body: 'Primary shaking has arrived. Stay safe!',
    );
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    state = MonitoringState.idle;

    _cameraService?.stopMotionDetection();
    await _audioService?.stopListening();
    await _sensorService?.stopMonitoring();
  }
}

final monitoringProvider = StateNotifierProvider<MonitoringNotifier, MonitoringState>((ref) {
  return MonitoringNotifier(ref);
});
