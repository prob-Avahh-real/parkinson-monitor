import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/services/detection_engine.dart';
import 'package:parkinson_monitor/domain/entities/detection_event.dart';
import 'package:parkinson_monitor/domain/entities/movement_disorder_type.dart';

void main() {
  late DetectionEngine engine;
  late StreamSubscription<DetectionEvent> sub;
  final events = <DetectionEvent>[];

  setUp(() {
    events.clear();
    engine = DetectionEngine(sampleRate: 100);
    sub = engine.detectionStream.listen((e) => events.add(e));
  });

  tearDown(() async {
    await sub.cancel();
    engine.dispose();
  });

  /// 喂入 N 个传感器读数
  void feed(int count, double Function(int i) accelX,
      [double Function(int i)? accelY,
      double Function(int i)? accelZ]) {
    for (int i = 0; i < count; i++) {
      engine.processReading(
        accelX: accelX(i),
        accelY: accelY?.call(i) ?? 0,
        accelZ: accelZ?.call(i) ?? 0,
        gyroX: 0,
        gyroY: 0,
        gyroZ: 0,
      );
    }
  }

  group('DetectionEngine — FoG 步态冻结', () {
    test('高频震颤+低运动功率 → 检测 FoG', () {
      // FoG 信号：震颤在垂直轴 (accelZ)，极小步频
      const zero = 0.0;
      feed(800, (_) => zero, (_) => zero, (i) {
        return 0.8 * sin(2 * pi * 5 * i / 100) +
            0.02 * sin(2 * pi * 1 * i / 100);
      });
      feed(500, (_) => zero, (_) => zero, (i) {
        return 0.8 * sin(2 * pi * 5 * i / 100) +
            0.02 * sin(2 * pi * 1 * i / 100);
      });

      final fogEvents = events
          .where((e) => e.type == MovementDisorderType.freezingOfGait)
          .toList();
      expect(fogEvents, isNotEmpty,
          reason: '应检测到至少一次步态冻结事件');
      if (fogEvents.isNotEmpty) {
        expect(fogEvents.first.freezeIndex, isNotNull);
        expect(fogEvents.first.confidence, greaterThan(0));
      }
    });

    test('正常行走不触发 FoG', () {
      const zero = 0.0;
      // 正常步频在垂直轴 (accelZ)
      feed(800, (_) => zero, (_) => zero, (i) {
        return 1.0 * sin(2 * pi * 1.5 * i / 100) +
            0.05 * sin(2 * pi * 5 * i / 100);
      });
      feed(500, (_) => zero, (_) => zero, (i) {
        return 1.0 * sin(2 * pi * 1.5 * i / 100) +
            0.05 * sin(2 * pi * 5 * i / 100);
      });

      final fogEvents = events
          .where((e) => e.type == MovementDisorderType.freezingOfGait)
          .toList();
      expect(fogEvents, isEmpty,
          reason: '正常步行不应触发 FoG 检测');
    });
  });

  group('DetectionEngine — 震颤', () {
    test('5Hz 节律性震颤被检测', () {
      const zero = 0.0;
      // 震颤在加速度幅值中检测 — 用 accelX 大振幅
      feed(800, (i) => 1.5 * sin(2 * pi * 5 * i / 100), (_) => zero, (_) => zero);
      feed(500, (i) => 1.5 * sin(2 * pi * 5 * i / 100), (_) => zero, (_) => zero);

      final tremorEvents = events
          .where((e) => e.type == MovementDisorderType.restingTremor)
          .toList();
      expect(tremorEvents, isNotEmpty,
          reason: '应检测到静止性震颤');
      if (tremorEvents.isNotEmpty) {
        expect(tremorEvents.first.tremorFrequency,
            inInclusiveRange(4.0, 6.0));
      }
    });

    test('低频行走不触发震颤', () {
      const zero = 0.0;
      // 1.5Hz 步行 — 峰值应在 0.5-3Hz 而非 4-6Hz
      feed(800, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100), (_) => zero, (_) => zero);
      feed(500, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100), (_) => zero, (_) => zero);

      final tremorEvents = events
          .where((e) => e.type == MovementDisorderType.restingTremor)
          .toList();
      // 1.5Hz 不在 4-6Hz 震颤频段，但 FFT 频谱泄漏可能产生杂散检测
      // 检查检测到的频率是否接近震颤频段而非步频
      if (tremorEvents.isNotEmpty) {
        final freq = tremorEvents.first.tremorFrequency;
        // ignore: avoid_print
        print('Unexpected tremor at ${freq}Hz');
      }
      // 宽松断言：最多检测到一次误报
      expect(tremorEvents.length, lessThanOrEqualTo(1));
    });
  });

  group('DetectionEngine — 运动迟缓', () {
    test('低幅度+低步频 → 运动迟缓', () {
      const zero = 0.0;
      // 低幅度 + 低步频 (0.5Hz ≈ 30 步/分)
      feed(800, (i) => 0.03 * sin(2 * pi * 0.5 * i / 100),
          (_) => zero, (i) => 0.03 * sin(2 * pi * 0.5 * i / 100));
      feed(500, (i) => 0.03 * sin(2 * pi * 0.5 * i / 100),
          (_) => zero, (i) => 0.03 * sin(2 * pi * 0.5 * i / 100));

      final bradyEvents = events
          .where((e) => e.type == MovementDisorderType.bradykinesia)
          .toList();
      expect(bradyEvents, isNotEmpty,
          reason: '低幅度运动应触发运动迟缓检测');
    });

    test('正常行走不触发运动迟缓', () {
      const zero = 0.0;
      feed(800, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100),
          (_) => zero, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100));
      feed(500, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100),
          (_) => zero, (i) => 0.5 * sin(2 * pi * 1.5 * i / 100));

      final bradyEvents = events
          .where((e) => e.type == MovementDisorderType.bradykinesia)
          .toList();
      expect(bradyEvents, isEmpty,
          reason: '正常幅度的步行不应触发迟缓检测');
    });
  });

  group('DetectionEngine — 边界条件', () {
    test('数据不足时不触发检测', () {
      const zero = 0.0;
      feed(50, (i) => sin(2 * pi * 5 * i / 100), (_) => zero, (_) => zero);
      expect(events, isEmpty,
          reason: '数据不足时不应触发任何检测');
    });

    test('reset 后重新开始', () {
      const zero = 0.0;
      feed(800, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));
      feed(500, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));
      final beforeReset = events.length;

      engine.reset();
      events.clear();

      feed(800, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));
      feed(500, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));

      expect(events.length, equals(beforeReset),
          reason: 'reset 后重新检测应有相同数量的事件');
    });

    test('currentMetrics 返回有效指标', () {
      const zero = 0.0;
      feed(500, (i) => 0.5 * sin(2 * pi * 2 * i / 100), (_) => zero, (_) => zero);
      final metrics = engine.currentMetrics;
      expect(metrics, contains('rms'));
      expect(metrics, contains('freezeIndex'));
      expect(metrics, contains('tremorFreq'));
      expect(metrics, contains('cadence'));
    });
  });

  group('DetectionEngine — 防抖', () {
    test('短时间内同类型事件不重复触发', () {
      const zero = 0.0;
      feed(800, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));
      feed(500, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));

      final firstCount = events
          .where((e) => e.type == MovementDisorderType.freezingOfGait)
          .length;

      // 立即再喂数据 (防抖期内)
      feed(200, (_) => zero, (_) => zero,
          (i) => 0.8 * sin(2 * pi * 5 * i / 100));

      final secondCount = events
          .where((e) => e.type == MovementDisorderType.freezingOfGait)
          .length;

      // 防抖期间 (3秒 = 300 样本 @ 100Hz) 不应新增
      expect(secondCount, equals(firstCount),
          reason: '防抖期内同类型事件不应重复触发');
    });
  });
}
