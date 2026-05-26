import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/device_repository.dart';

part 'device_event.dart';
part 'device_state.dart';

/// 设备连接 BLoC
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository _deviceRepository;
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;

  DeviceBloc({required this._deviceRepository}) : super(const DeviceState()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnect);
    on<DisconnectDevice>(_onDisconnect);
    on<DeviceScanResult>(_onScanResult);
    on<_ConnectionChanged>(_onConnectionChanged);
    on<_ScanError>(_onScanError);

    // 监听连接状态
    _connectionSub = _deviceRepository.connectionState.listen((connected) {
      add(_ConnectionChanged(connected));
    });
  }

  Future<void> _onStartScan(StartScan event, Emitter<DeviceState> emitter) async {
    emitter(state.copyWith(isScanning: true, scannedDevices: [], error: null));

    final seenIds = <String>{};
    _scanSub = _deviceRepository.scanDevices().listen(
      (device) {
        final id = device['id'] as String;
        if (!seenIds.contains(id)) {
          seenIds.add(id);
          add(DeviceScanResult(device));
        }
      },
      onError: (error) {
        add(_ScanError('扫描失败: $error'));
      },
    );
  }

  void _onScanResult(DeviceScanResult event, Emitter<DeviceState> emitter) {
    final updated = List<Map<String, dynamic>>.from(state.scannedDevices)
      ..add(event.device);
    // 按 RSSI 排序
    updated.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));
    emitter(state.copyWith(scannedDevices: updated));
  }

  void _onStopScan(StopScan event, Emitter<DeviceState> emitter) {
    _scanSub?.cancel();
    emitter(state.copyWith(isScanning: false));
  }

  Future<void> _onConnect(
      ConnectToDevice event, Emitter<DeviceState> emitter) async {
    emitter(state.copyWith(error: null));
    final success = await _deviceRepository.connect(event.deviceId);
    if (!success) {
      emitter(state.copyWith(error: '连接失败'));
    }
  }

  void _onDisconnect(DisconnectDevice event, Emitter<DeviceState> emitter) async {
    await _deviceRepository.disconnect();
  }

  void _onScanError(_ScanError event, Emitter<DeviceState> emitter) {
    emitter(state.copyWith(isScanning: false, error: event.message));
  }

  void _onConnectionChanged(
      _ConnectionChanged event, Emitter<DeviceState> emitter) {
    if (event.connected) {
      emitter(state.copyWith(
        isConnected: true,
        connectedDevice: _deviceRepository.connectedDevice,
        error: null,
      ));
    } else {
      emitter(state.copyWith(
        isConnected: false,
        connectedDevice: null,
      ));
    }
  }

  @override
  Future<void> close() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    return super.close();
  }
}
