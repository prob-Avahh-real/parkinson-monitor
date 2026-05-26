import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/core/utils/signal_processor.dart';

void main() {
  late SignalProcessor processor;

  setUp(() {
    processor = SignalProcessor(sampleRate: 100);
  });

  group('SignalProcessor — FFT', () {
    test('单频正弦波 FFT 在正确频率出现峰值', () {
      const freq = 5.0;
      const sampleRate = 100;
      const n = 256;
      final signal = List<double>.generate(
          n, (i) => sin(2 * pi * freq * i / sampleRate));

      final mags = SignalProcessor.fftMagnitudes(signal);
      final freqRes = sampleRate / (2.0 * mags.length);
      final expectedBin = (freq / freqRes).round();
      final peakMag = mags[expectedBin];
      final avgMag = mags.reduce((a, b) => a + b) / mags.length;

      expect(peakMag, greaterThan(avgMag * 5),
          reason: '5Hz 分量的幅度应显著高于平均幅度');
    });

    test('直流信号 FFT 仅 bin 0 有值', () {
      final signal = List<double>.filled(128, 1.0);
      final mags = SignalProcessor.fftMagnitudes(signal);
      expect(mags[0], greaterThan(0));
      for (int i = 1; i < mags.length; i++) {
        expect(mags[i], lessThan(1e-10));
      }
    });
  });

  group('SignalProcessor — bandPower', () {
    test('bandPower 正确区分频带', () {
      const n = 256;
      final signal = List<double>.generate(n, (i) {
        return sin(2 * pi * 5 * i / 100) +
            0.5 * sin(2 * pi * 10 * i / 100);
      });
      final mags = SignalProcessor.fftMagnitudes(signal);
      final powerLow = processor.bandPower(mags, 4, 6);
      final powerHigh = processor.bandPower(mags, 9, 11);
      expect(powerLow, greaterThan(powerHigh),
          reason: '5Hz 频带功率应大于 10Hz 频带');
    });
  });

  group('SignalProcessor — freezeIndex', () {
    test('正常行走冻结指数低', () {
      const n = 256;
      final signal = List<double>.generate(n, (i) {
        return sin(2 * pi * 1.5 * i / 100) +
            0.1 * sin(2 * pi * 5 * i / 100) +
            0.2 * (Random(i).nextDouble() - 0.5);
      });
      expect(processor.freezeIndex(signal), lessThan(1.8));
    });

    test('冻结步态冻结指数高', () {
      const n = 256;
      final signal = List<double>.generate(n, (i) {
        return 0.8 * sin(2 * pi * 5 * i / 100) +
            0.1 * sin(2 * pi * 1 * i / 100);
      });
      expect(processor.freezeIndex(signal), greaterThan(1.8));
    });
  });

  group('SignalProcessor — tremorPeakFrequency', () {
    test('检测 5Hz 震颤', () {
      const n = 256;
      final signal = List<double>.generate(
          n, (i) => sin(2 * pi * 5 * i / 100));
      final peak = processor.tremorPeakFrequency(signal);
      expect(peak, isNotNull);
      expect(peak!, inInclusiveRange(4.5, 5.5));
    });

    test('检测 4Hz 震颤', () {
      const n = 256;
      final signal = List<double>.generate(
          n, (i) => sin(2 * pi * 4 * i / 100));
      final peak = processor.tremorPeakFrequency(signal);
      expect(peak, isNotNull);
      expect(peak!, inInclusiveRange(3.5, 4.5));
    });
  });

  group('SignalProcessor — 时域', () {
    test('RMS 正确', () {
      final r = processor.rms([1.0, 2.0, 3.0, 4.0, 5.0]);
      expect(r, inInclusiveRange(3.3, 3.32));
    });

    test('amplitude 峰峰值', () {
      expect(processor.amplitude([-2, 1, 3, -1, 0]), equals(5.0));
    });

    test('zeroCrossings', () {
      expect(processor.zeroCrossings([1, -1, 1, -1, 1]), equals(4));
    });
  });

  group('SignalProcessor — 滑动窗口', () {
    test('窗口大小正确维护', () {
      for (int i = 0; i < 700; i++) {
        processor.addReading(i.toDouble(), 0, 0, 0, 0, 0);
      }
      expect(processor.bufferSize, equals(600));
    });

    test('clear 清空', () {
      for (int i = 0; i < 100; i++) {
        processor.addReading(1, 0, 0, 0, 0, 0);
      }
      processor.clear();
      expect(processor.bufferSize, equals(0));
    });
  });
}
