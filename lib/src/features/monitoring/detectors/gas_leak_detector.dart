import 'dart:math';

class GasLeakDetector {
  static const double confidenceThreshold = 0.75;

  List<double>? _trainedFeatures;
  bool get isTrained => _trainedFeatures != null;

  /// Train on gas hiss sound samples
  /// Extracts MFCC-like features from 5-second audio
  void train(List<double> audioSamples, int sampleRate) {
    final frameSize = (sampleRate * 0.025).round(); // 25ms frames
    final hopSize = (sampleRate * 0.010).round(); // 10ms hop
    final numFilters = 13; // 13 MFCC coefficients

    _trainedFeatures = _extractFeatures(audioSamples, frameSize, hopSize, numFilters);
  }

  /// Detect gas hiss from live audio
  /// Returns confidence score 0.0 - 1.0
  double detect(List<double> audioSamples, int sampleRate) {
    if (!isTrained) return 0;

    final frameSize = (sampleRate * 0.025).round();
    final hopSize = (sampleRate * 0.010).round();
    const numFilters = 13;

    final liveFeatures = _extractFeatures(audioSamples, frameSize, hopSize, numFilters);
    if (liveFeatures.isEmpty) return 0;

    return _compareFeatures(liveFeatures);
  }

  List<double> _extractFeatures(
    List<double> samples,
    int frameSize,
    int hopSize,
    int numFilters,
  ) {
    final features = <double>[];

    for (int start = 0; start < samples.length - frameSize; start += hopSize) {
      final frame = samples.sublist(start, start + frameSize);
      final windowed = _applyHammingWindow(frame);
      final spectrum = _computePowerSpectrum(windowed);
      final melSpectrum = _applyMelFilterBank(spectrum, numFilters);
      final logEnergy = melSpectrum.map(log).toList();
      final mfcc = _computeDCT(logEnergy);

      if (features.isEmpty) {
        features.addAll(mfcc);
      } else {
        // Average with existing features
        for (int i = 0; i < mfcc.length && i < features.length; i++) {
          features[i] = (features[i] + mfcc[i]) / 2;
        }
      }
    }

    return features;
  }

  List<double> _applyHammingWindow(List<double> frame) {
    return List.generate(frame.length, (i) {
      return frame[i] * (0.54 - 0.46 * cos(2 * pi * i / (frame.length - 1)));
    });
  }

  List<double> _computePowerSpectrum(List<double> windowed) {
    // Simplified: compute magnitude spectrum via autocorrelation
    final spectrum = <double>[];
    for (int k = 0; k < windowed.length ~/ 2; k++) {
      double real = 0, imag = 0;
      for (int n = 0; n < windowed.length; n++) {
        final theta = -2 * pi * k * n / windowed.length;
        real += windowed[n] * cos(theta);
        imag += windowed[n] * sin(theta);
      }
      spectrum.add(real * real + imag * imag);
    }
    return spectrum;
  }

  List<double> _applyMelFilterBank(List<double> spectrum, int numFilters) {
    final melSpectrum = <double>[];
    final maxMel = 2595 * log(1 + 4000 / 700);
    final melStep = maxMel / (numFilters + 1);

    for (int m = 0; m < numFilters; m++) {
      final center = 700 * (pow(10, (m + 1) * melStep / 2595) - 1);
      final centerBin = (center / (4000 / spectrum.length)).round();
      if (centerBin < spectrum.length) {
        melSpectrum.add(log(max(1e-10, spectrum[centerBin])));
      }
    }
    return melSpectrum;
  }

  List<double> _computeDCT(List<double> input) {
    final output = <double>[];
    for (int k = 0; k < input.length; k++) {
      double sum = 0;
      for (int n = 0; n < input.length; n++) {
        sum += input[n] * cos(pi * k * (n + 0.5) / input.length);
      }
      output.add(sum);
    }
    return output;
  }

  double _compareFeatures(List<double> liveFeatures) {
    if (_trainedFeatures == null || liveFeatures.length != _trainedFeatures!.length) {
      return 0;
    }

    double distance = 0;
    for (int i = 0; i < liveFeatures.length; i++) {
      distance += pow(liveFeatures[i] - _trainedFeatures![i], 2);
    }
    distance = sqrt(distance / liveFeatures.length);

    // Convert distance to confidence (closer = higher confidence)
    return max(0, min(1, 1 - distance / 10));
  }
}
