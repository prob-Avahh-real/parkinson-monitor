// Domain entities used via repository interface

/// 设备仓库接口
abstract class DeviceRepository {
  /// 扫描可用 BLE 设备
  Stream<Map<String, dynamic>> scanDevices();

  /// 连接到指定设备
  Future<bool> connect(String deviceId);

  /// 断开连接
  Future<void> disconnect();

  /// 当前连接状态
  Stream<bool> get connectionState;

  /// 已连接设备信息
  Map<String, dynamic>? get connectedDevice;
}
