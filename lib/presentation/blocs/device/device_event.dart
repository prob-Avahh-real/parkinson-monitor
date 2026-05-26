part of 'device_bloc.dart';

/// 设备事件
sealed class DeviceEvent {
  const DeviceEvent();
}

class StartScan extends DeviceEvent {
  const StartScan();
}

class StopScan extends DeviceEvent {
  const StopScan();
}

class ConnectToDevice extends DeviceEvent {
  final String deviceId;
  const ConnectToDevice(this.deviceId);
}

class DisconnectDevice extends DeviceEvent {
  const DisconnectDevice();
}

class DeviceScanResult extends DeviceEvent {
  final Map<String, dynamic> device;
  const DeviceScanResult(this.device);
}

class _ConnectionChanged extends DeviceEvent {
  final bool connected;
  const _ConnectionChanged(this.connected);
}

class _ScanError extends DeviceEvent {
  final String message;
  const _ScanError(this.message);
}
