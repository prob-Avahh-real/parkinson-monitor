import 'dart:async';
import '../../domain/repositories/device_repository.dart';
import '../../services/ble_service.dart';

/// 设备仓库实现
class DeviceRepositoryImpl implements DeviceRepository {
  final BleService _bleService;

  DeviceRepositoryImpl({required this._bleService});

  @override
  Stream<Map<String, dynamic>> scanDevices() {
    _bleService.startScan();
    return _bleService.deviceScan;
  }

  @override
  Future<bool> connect(String deviceId) async {
    return _bleService.connect(deviceId);
  }

  @override
  Future<void> disconnect() async {
    await _bleService.disconnect();
  }

  @override
  Stream<bool> get connectionState => _bleService.connectionState;

  @override
  Map<String, dynamic>? get connectedDevice {
    final device = _bleService.connectedDevice;
    if (device == null) return null;
    return {
      'id': device.remoteId.str,
      'name': device.platformName,
    };
  }
}
