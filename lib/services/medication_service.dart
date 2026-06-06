import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/medication_record.dart';

/// 用药记录服务 — 记录用药时间，可选同步到 Supabase
///
/// 当前版本：本地 Hive 存储，未来可扩展 Supabase 同步。
/// 用药记录是 Agent 分析"药物-症状关联"的关键输入。
class MedicationService {
  final _uuid = const Uuid();
  final _records = <MedicationRecord>[];
  final _controller =
      StreamController<MedicationRecord>.broadcast();

  Stream<MedicationRecord> get recordStream => _controller.stream;

  static const _boxName = 'medication';
  static const _keyRecords = 'records';

  /// 初始化：从 Hive 加载历史记录
  Future<void> load() async {
    final box = await Hive.openBox<String>(_boxName);
    final json = box.get(_keyRecords);
    if (json == null) return;
    // 简单恢复（不需要强序列化）
    final lines = json.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 2) {
        _records.add(MedicationRecord(
          id: parts[0],
          recordedAt: DateTime.parse(parts[1]),
          medicationName: parts.length > 2 ? parts[2] : '左旋多巴',
        ));
      }
    }
  }

  /// 记录一次用药
  Future<MedicationRecord> record({
    String medicationName = '左旋多巴',
    double? dosageMg,
    String? note,
  }) async {
    final record = MedicationRecord(
      id: _uuid.v4(),
      recordedAt: DateTime.now(),
      medicationName: medicationName,
      dosageMg: dosageMg,
      note: note,
    );
    _records.insert(0, record);

    // 保留最近 365 条
    while (_records.length > 365) {
      _records.removeLast();
    }

    await _save();
    _controller.add(record);
    return record;
  }

  /// 获取最近的用药记录
  List<MedicationRecord> getRecent({int count = 10}) {
    return _records.take(count).toList();
  }

  /// 获取今天的用药记录
  List<MedicationRecord> getToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _records
        .where((r) => r.recordedAt.isAfter(start))
        .toList();
  }

  /// 上次用药到现在的小时数
  double? get hoursSinceLastMedication {
    if (_records.isEmpty) return null;
    final last = _records.first;
    return DateTime.now()
        .difference(last.recordedAt)
        .inMinutes / 60.0;
  }

  /// 今天是否已经用药
  bool get hasTakenToday => getToday().isNotEmpty;

  /// 距离上次用药时间文本
  String get timeSinceLastText {
    if (_records.isEmpty) return '今日未记录';
    final hours = hoursSinceLastMedication;
    if (hours == null) return '未知';
    if (hours < 1) return '${(hours * 60).round()} 分钟前';
    return '${hours.toStringAsFixed(1)} 小时前';
  }

  Future<void> _save() async {
    final box = await Hive.openBox<String>(_boxName);
    final lines = _records
        .map((r) => '${r.id}|${r.recordedAt.toIso8601String()}|${r.medicationName}')
        .join('\n');
    await box.put(_keyRecords, lines);
  }

  void dispose() {
    _controller.close();
  }
}
