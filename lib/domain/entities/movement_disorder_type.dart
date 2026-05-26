/// 帕金森运动障碍类型
enum MovementDisorderType {
  /// 步态冻结 — Freezing of Gait (FoG)
  freezingOfGait,

  /// 静止性震颤 — Resting Tremor (4-6 Hz)
  restingTremor,

  /// 运动迟缓 — Bradykinesia
  bradykinesia,

  /// 姿势不稳 — Postural Instability
  posturalInstability,

  /// 正常
  normal,
}

/// 严重程度
enum Severity { mild, moderate, severe }

/// 活动模式
enum ActivityMode { indoor, outdoor }
