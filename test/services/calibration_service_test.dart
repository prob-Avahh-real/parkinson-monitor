import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/services/calibration_service.dart';

void main() {
  group('CalibrationService', () {
    test('startCalibration 初始化状态', () {
      final service = CalibrationService(sampleRate: 100);
      service.startCalibration();

      expect(service.isCalibrating, isTrue);
      expect(service.progress, equals(0));
      expect(service.samplesCollected, equals(0));

      service.dispose();
    });

    test('finishCalibration 无数据时返回默认阈值', () {
      final service = CalibrationService(sampleRate: 100);
      service.startCalibration();
      final result = service.finishCalibration();

      expect(result.fogThreshold, equals(1.8));
      expect(result.tremorPowerThreshold, equals(0.3));
      expect(result.bradyAmplitudeThreshold, equals(0.15));
      expect(result.bradyCadenceThreshold, equals(40));

      service.dispose();
    });

    test('正常步行数据产生合理阈值', () {
      final service = CalibrationService(sampleRate: 100);
      service.startCalibration();

      // 喂入 300 个正常步行样本 (1.5Hz + 噪声)
      for (int i = 0; i < 300; i++) {
        service.processReading(
          accelX: 0.5 * sin(2 * pi * 1.5 * i / 100) +
              0.1 * (Random(i).nextDouble() - 0.5),
          accelY: 0.2 * sin(2 * pi * 1.5 * i / 100),
          accelZ: 0.6 * sin(2 * pi * 1.5 * i / 100),
          gyroX: 0,
          gyroY: 0,
          gyroZ: 0,
        );
      }

      final result = service.finishCalibration();

      // FoG 阈值应在 1.2-3.0 范围
      expect(result.fogThreshold, inInclusiveRange(1.2, 3.0));
      // 震颤阈值应在 0.15-1.0
      expect(result.tremorPowerThreshold, inInclusiveRange(0.15, 1.0));
      // 迟缓幅值阈值应在 0.05-0.3
      expect(result.bradyAmplitudeThreshold, inInclusiveRange(0.05, 0.3));
      // 步频阈值应在 25-60
      expect(result.bradyCadenceThreshold, inInclusiveRange(25, 60));

      service.dispose();
    });

    test('达到目标样本数自动停止', () {
      final service = CalibrationService(sampleRate: 100);
      service.startCalibration();

      // 喂 300 个样本
      for (int i = 0; i < 300; i++) {
        service.processReading(
          accelX: 0.5 * sin(2 * pi * 1.5 * i / 100),
          accelY: 0,
          accelZ: 0.5 * sin(2 * pi * 1.5 * i / 100),
          gyroX: 0,
          gyroY: 0,
          gyroZ: 0,
        );
      }

      expect(service.isCalibrating, isFalse,
          reason: '达到 300 样本后应自动停止');
      expect(service.samplesCollected, greaterThanOrEqualTo(300));

      service.dispose();
    });

    test('processReading 非校准状态不处理', () {
      final service = CalibrationService(sampleRate: 100);
      // 未调用 startCalibration

      for (int i = 0; i < 100; i++) {
        service.processReading(
          accelX: 1.0,
          accelY: 0,
          accelZ: 0,
          gyroX: 0,
          gyroY: 0,
          gyroZ: 0,
        );
      }

      expect(service.samplesCollected, equals(0));
      service.dispose();
    });

    test('progress 正确反映进度', () {
      final service = CalibrationService(sampleRate: 100);
      service.startCalibration();

      expect(service.progress, equals(0));

      for (int i = 0; i < 150; i++) {
        service.processReading(
          accelX: 0.5,
          accelY: 0,
          accelZ: 0.5,
          gyroX: 0,
          gyroY: 0,
          gyroZ: 0,
        );
      }

      expect(service.progress, inInclusiveRange(0.45, 0.55));
      service.dispose();
    });
  });
}
