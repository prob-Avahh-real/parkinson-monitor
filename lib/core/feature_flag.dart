/// 最小化 Feature Flag — 零依赖
///
/// 控制逻辑不是环境变量（太粗），也不是代码分支（太慢）。
/// 用法：
/// ```dart
/// if (FeatureFlag('ml_detection_engine').isEnabled) { ... }
/// ```
///
/// 生产时改 `_flags` 映射即可，无需重新部署逻辑。
class FeatureFlag {
  final String key;
  const FeatureFlag(this.key);

  bool get isEnabled => _flags[key] ?? false;

  /// 所有 flag 集中定义在这里
  static const Map<String, bool> _flags = {
    // parkinson-monitor
    'ml_detection_engine': false,       // ML双引擎检测（模型准确率验证后再开启）
    'supabase_cloud_sync': true,        // 云同步
    'pdf_report_export': true,          // PDF报告导出
    'medication_tracking': false,       // 用药追踪（v2 功能）
  };
}
