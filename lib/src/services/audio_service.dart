import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioAnalysisResult {
  final double confidence;
  final String type; // 'glass', 'fire_alarm', 'gas_hiss', 'water'
  final Map<String, dynamic> metadata;

  AudioAnalysisResult({
    required this.confidence,
    required this.type,
    this.metadata = const {},
  });

  bool get isDetected => confidence > 0.6;
}

class AudioService {
  final _recorder = AudioRecorder();
  StreamSubscription? _recordingSubscription;
  Timer? _analysisTimer;
  bool _isListening = false;

  // FFT buffers
  List<double> _audioBuffer = [];
  static const int bufferSize = 4096;

  bool get isListening => _isListening;

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startListening({
    required Function(AudioAnalysisResult) onAnalysis,
  }) async {
    if (_isListening) return;

    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 44100,
      numChannels: 1,
    );

    await _recorder.startStream(config);
    _isListening = true;

    _recordingSubscription = _recorder.onAudio().listen(
      (data) {
        _audioBuffer.addAll(_samplesFromBytes(data));
        if (_audioBuffer.length >= bufferSize) {
          final frame = _audioBuffer.take(bufferSize).toList();
          _audioBuffer = _audioBuffer.skip(bufferSize).toList();
          final result = analyzeFrame(frame);
          onAnalysis(result);
        }
      },
    );
  }

  List<double> _samplesFromBytes(Uint8List bytes) {
    final samples = <double>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      final sample = (bytes[i] | (bytes[i + 1] << 8)).toSigned(16);
      samples.add(sample / 32768.0);
    }
    return samples;
  }

  AudioAnalysisResult analyzeFrame(List<double> frame) {
    final fft = _runFFT(frame);
    final magnitudes = _computeMagnitudes(fft);
    final frequencies = _computeFrequencies(magnitudes);

    final glassConfidence = _detectGlassBreak(frequencies, frame);
    final fireAlarmConfidence = _detectFireAlarm(frequencies);
    final waterConfidence = _detectWaterSound(frequencies);

    final results = [
      if (glassConfidence > 0.6) ('glass', glassConfidence),
      if (fireAlarmConfidence > 0.6) ('fire_alarm', fireAlarmConfidence),
      if (waterConfidence > 0.6) ('water', waterConfidence),
    ];

    if (results.isEmpty) {
      return AudioAnalysisResult(confidence: 0, type: 'none');
    }

    results.sort((a, b) => b.$2.compareTo(a.$2));
    return AudioAnalysisResult(
      confidence: results.first.$2,
      type: results.first.$1,
    );
  }

  List<Complex> _runFFT(List<double> samples) {
    final n = samples.length;
    final buffer = List<Complex>.generate(
      n,
      (i) => Complex(samples[i], 0),
    );
    _fft(buffer, n, 1);
    return buffer;
  }

  void _fft(List<Complex> buffer, int n, int step) {
    if (n <= 1) return;
    final half = n ~/ 2;
    final even = List<Complex>.generate(half, (i) => buffer[i * step * 2]);
    final odd = List<Complex>.generate(half, (i) => buffer[i * step * 2 + step]);

    _fft(even, half, step * 2);
    _fft(odd, half, step * 2);

    for (int k = 0; k < half; k++) {
      final t = Complex.fromPolar(1, -2 * pi * k / n) * odd[k];
      buffer[k * step] = even[k] + t;
      buffer[k * step + half * step] = even[k] - t;
    }
  }

  List<double> _computeMagnitudes(List<Complex> fft) {
    return fft.map((c) => sqrt(c.real * c.real + c.imag * c.imag)).toList();
  }

  List<double> _computeFrequencies(List<double> magnitudes) {
    final half = magnitudes.length ~/ 2;
    final result = List<double>.generate(
      half,
      (i) => magnitudes[i] / half,
    );
    return result;
  }

  double _detectGlassBreak(List<double> frequencies, List<double> rawSamples) {
    // Glass break: 2000-5000 Hz spike with sharp attack (<10ms) + 200ms decay
    final sampleRate = 44100;
    final binSize = sampleRate / bufferSize;

    final minBin = (2000 / binSize).round();
    final maxBin = (5000 / binSize).round();

    double energyInBand = 0;
    for (int i = minBin; i < maxBin && i < frequencies.length; i++) {
      energyInBand += frequencies[i];
    }

    // Check for sharp attack (first 10ms)
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

  double _detectFireAlarm(List<double> frequencies) {
    // Smoke alarm: 3 consecutive beeps, each 0.5s, 1.5s pause
    final sampleRate = 44100;
    final binSize = sampleRate / bufferSize;

    // Fire alarms typically have strong components around 3000-4000 Hz
    final minBin = (3000 / binSize).round();
    final maxBin = (4000 / binSize).round();

    double peakEnergy = 0;
    for (int i = minBin; i < maxBin && i < frequencies.length; i++) {
      if (frequencies[i] > peakEnergy) {
        peakEnergy = frequencies[i];
      }
    }

    return min(1.0, peakEnergy * 1.5);
  }

  double _detectWaterSound(List<double> frequencies) {
    // Water: broadband noise 100-4000Hz, with splashing 500-1500Hz
    final sampleRate = 44100;
    final binSize = sampleRate / bufferSize;

    final minBin = (100 / binSize).round();
    final maxBin = (4000 / binSize).round();

    double totalEnergy = 0;
    double splashEnergy = 0;
    for (int i = minBin; i < maxBin && i < frequencies.length; i++) {
      totalEnergy += frequencies[i];
      if (i >= (500 / binSize).round() && i <= (1500 / binSize).round()) {
        splashEnergy += frequencies[i];
      }
    }

    final broadbandRatio = totalEnergy / max(1, (maxBin - minBin));
    if (broadbandRatio > 0.01 && splashEnergy / max(1, totalEnergy) > 0.2) {
      return min(1.0, splashEnergy * 3);
    }
    return 0;
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _recordingSubscription?.cancel();
    await _recorder.stop();
    _audioBuffer.clear();
  }

  Future<String> saveAudioClip() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/audio_$timestamp.wav';
    return path;
  }

  void dispose() {
    stopListening();
    _recorder.dispose();
  }
}

class Complex {
  final double real;
  final double imag;

  Complex(this.real, this.imag);

  factory Complex.fromPolar(double r, double theta) {
    return Complex(r * cos(theta), r * sin(theta));
  }

  Complex operator +(Complex other) => Complex(real + other.real, imag + other.imag);
  Complex operator -(Complex other) => Complex(real - other.real, imag - other.imag);
  Complex operator *(Complex other) => Complex(
    real * other.real - imag * other.imag,
    real * other.imag + imag * other.real,
  );
}
