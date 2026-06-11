import 'dart:math';
import '../../services/audio_service.dart';

class GlassBreakDetector {
  static const int minFreq = 2000;
  static const int maxFreq = 5000;
  static const double confidenceThreshold = 0.8;

  /// Detect glass break from FFT analysis
  /// Glass break characteristics:
  /// - Frequency spike between 2000-5000 Hz
  /// - Sharp attack (<10ms) + 200ms decay
  static double detect(List<double> frequencies, List<double> rawSamples, int sampleRate) {
    final binSize = sampleRate / frequencies.length;
    final minBin = (minFreq / binSize).round();
    final maxBin = (maxFreq / binSize).round();

    double energyInBand = 0;
    for (int i = minBin; i < maxBin && i < frequencies.length; i++) {
      energyInBand += frequencies[i];
    }

    // Sharp attack detection
    final attackSamples = (sampleRate * 0.01).round();
    if (rawSamples.length > attackSamples) {
      double attackEnergy = 0;
      for (int i = 0; i < attackSamples; i++) {
        attackEnergy += rawSamples[i].abs();
      }
      attackEnergy /= attackSamples;

      double decayEnergy = 0;
      final decayStart = attackSamples;
      final decayEnd = (decayStart + sampleRate * 0.2).round();
      for (int i = decayStart; i < decayEnd && i < rawSamples.length; i++) {
        decayEnergy += rawSamples[i].abs();
      }
      decayEnergy /= (decayEnd - decayStart);

      if (attackEnergy > 0 && attackEnergy / decayEnergy > 3) {
        return min(1.0, energyInBand * 2);
      }
    }

    return 0;
  }
}
