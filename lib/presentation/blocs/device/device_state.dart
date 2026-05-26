part of 'device_bloc.dart';

/// 设备状态
class DeviceState {
  final bool isScanning;
  final bool isConnected;
  final List<Map<String, dynamic>> scannedDevices;
  final Map<String, dynamic>? connectedDevice;
  final String? error;

  const DeviceState({
    this.isScanning = false,
    this.isConnected = false,
    this.scannedDevices = const [],
    this.connectedDevice,
    this.error,
  });

  DeviceState copyWith({
    bool? isScanning,
    bool? isConnected,
    List<Map<String, dynamic>>? scannedDevices,
    Map<String, dynamic>? connectedDevice,
    String? error,
  }) {
    return DeviceState(
      isScanning: isScanning ?? this.isScanning,
      isConnected: isConnected ?? this.isConnected,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      error: error,
    );
  }
}
