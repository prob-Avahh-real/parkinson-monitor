import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../domain/entities/detection_event.dart';
import '../domain/entities/movement_disorder_type.dart';

/// 反馈服务 — 声音、振动、视觉提示
class FeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 上次触发的反馈类型，用于去重
  MovementDisorderType? _lastFeedbackType;
  DateTime _lastFeedbackTime = DateTime(2000);
  static const _feedbackCooldown = Duration(seconds: 5);

  /// 根据检测事件触发反馈
  Future<void> triggerFeedback(DetectionEvent event) async {
    final now = DateTime.now();

    // 同类型冷却
    if (event.type == _lastFeedbackType &&
        now.difference(_lastFeedbackTime) < _feedbackCooldown) {
      return;
    }

    _lastFeedbackType = event.type;
    _lastFeedbackTime = now;

    switch (event.type) {
      case MovementDisorderType.freezingOfGait:
        await _fogFeedback(event);
        break;
      case MovementDisorderType.restingTremor:
        await _tremorFeedback(event);
        break;
      case MovementDisorderType.bradykinesia:
        await _bradyFeedback(event);
        break;
      default:
        break;
    }
  }

  /// 步态冻结反馈 — 节奏性声音引导起步
  Future<void> _fogFeedback(DetectionEvent event) async {
    // 振动模式：短-短-长
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 200);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 200);
      await Future.delayed(const Duration(milliseconds: 100));
      await Vibration.vibrate(duration: 600);
    }

    // 播放节拍音引导起步 (1-2-3, 走!)
    try {
      for (int i = 0; i < 3; i++) {
        await _audioPlayer.play(AssetSource('sounds/beat.wav'));
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (_) {
      // 音频文件可能不存在，静默处理
    }
  }

  /// 震颤反馈 — 温和提醒
  Future<void> _tremorFeedback(DetectionEvent event) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 300);
    }
  }

  /// 运动迟缓反馈 — 激励提示
  Future<void> _bradyFeedback(DetectionEvent event) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 150);
      await Future.delayed(const Duration(milliseconds: 200));
      await Vibration.vibrate(duration: 150);
    }
  }

  /// 连接成功反馈
  Future<void> connectedFeedback() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 100);
    }
  }

  /// 断开连接反馈
  Future<void> disconnectedFeedback() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      await Vibration.vibrate(duration: 100);
      await Future.delayed(const Duration(milliseconds: 300));
      await Vibration.vibrate(duration: 100);
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
