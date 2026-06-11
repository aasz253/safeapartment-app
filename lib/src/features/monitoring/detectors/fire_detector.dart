import 'dart:math';

class FireDetector {
  static const double confidenceThreshold = 0.85;

  /// Detect fire from pixel analysis
  /// Fire characteristics:
  /// - Orange/red flickering regions (RGB: R>200, G<150, B<100)
  /// - Temporal variance in fire regions
  static double detect(List<int> rgbaBytes, int width, int height) {
    int firePixels = 0;
    int totalPixels = width * height;
    int fireRegionChanges = 0;

    for (int i = 0; i < rgbaBytes.length; i += 4) {
      final r = rgbaBytes[i];
      final g = rgbaBytes[i + 1];
      final b = rgbaBytes[i + 2];

      // Detect orange/red fire colors
      if (r > 200 && g < 150 && b < 100 && r > g && g > b) {
        firePixels++;
      }
    }

    final fireRatio = firePixels / max(1, totalPixels);
    return min(1.0, fireRatio * 5);
  }

  /// Detect smoke alarm sound pattern:
  /// 3 consecutive beeps (0.5s each), 1.5s pause, 5s silence, repeat
  static double detectSmokeAlarm(List<double> amplitudes, int sampleRate) {
    int beepCount = 0;
    bool inBeep = false;
    int beepSamples = 0;
    int silenceSamples = 0;

    final beepThreshold = 0.1;
    final minBeepSamples = (sampleRate * 0.3).round();
    final maxBeepSamples = (sampleRate * 0.7).round();
    final minPauseSamples = (sampleRate * 1.0).round();
    final maxPauseSamples = (sampleRate * 2.0).round();

    for (final amp in amplitudes) {
      if (amp > beepThreshold) {
        if (!inBeep) {
          inBeep = true;
          beepSamples = 0;
        }
        beepSamples++;
      } else {
        if (inBeep) {
          inBeep = false;
          silenceSamples = 0;
          if (beepSamples >= minBeepSamples && beepSamples <= maxBeepSamples) {
            beepCount++;
          }
        } else {
          silenceSamples++;
          if (beepCount >= 3 && silenceSamples >= minPauseSamples) {
            if (silenceSamples <= maxPauseSamples) {
              return 0.9; // Pattern matches smoke alarm
            }
            beepCount = 0;
          }
        }
      }
    }

    return 0;
  }
}
