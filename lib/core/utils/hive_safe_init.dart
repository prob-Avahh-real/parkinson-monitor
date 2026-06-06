import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive 本地存储安全初始化
///
/// 移动端文件系统不可靠——Hive box 损坏时必须自动恢复，否则 app 崩溃。
/// 这是约束，不是选择。
class HiveSafeInit {
  /// 安全打开 box：损坏时自动删除并重建
  static Future<Box<T>> openBox<T>(
    String name, {
    HiveCipher? encryptionCipher,
  }) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: encryptionCipher);
    } on HiveError catch (e) {
      debugPrint('[HiveSafeInit] Box "$name" corrupted: ${e.message}. Recreating...');

      // 尝试删除损坏的 box
      try {
        await Hive.deleteBoxFromDisk(name);
      } catch (_) {
        debugPrint('[HiveSafeInit] Could not delete corrupted box "$name"');
      }

      // 重建空 box
      try {
        return await Hive.openBox<T>(name, encryptionCipher: encryptionCipher);
      } catch (e2) {
        debugPrint('[HiveSafeInit] Failed to recreate box "$name": $e2');
        rethrow;
      }
    } catch (e) {
      debugPrint('[HiveSafeInit] Unexpected error opening "$name": $e');
      rethrow;
    }
  }

  /// 安全打开多个 box
  static Future<void> openBoxes(Map<String, HiveCipher?> boxes) async {
    for (final entry in boxes.entries) {
      await openBox(entry.key, encryptionCipher: entry.value);
    }
  }
}
