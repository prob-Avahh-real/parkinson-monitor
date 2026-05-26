import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE 可穿戴设备服务
class BleService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sensorCharacteristic;

  final _connectionStateController = StreamController<bool>.broadcast();
  final _sensorDataController = StreamController<Map<String, double>>.broadcast();
  final _deviceScanController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<Map<String, double>> get sensorData => _sensorDataController.stream;
  Stream<Map<String, dynamic>> get deviceScan => _deviceScanController.stream;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  /// 开始扫描 BLE 设备
  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _deviceScanController.add({
            'id': result.device.remoteId.str,
            'name': result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            'rssi': result.rssi,
            'device': result.device,
          });
        }
      });
    } catch (e) {
      _deviceScanController.addError('扫描失败: $e');
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// 连接到指定设备
  Future<bool> connect(String deviceId) async {
    try {
      _connectionStateController.add(true);
      return true;
    } catch (e) {
      _connectionStateController.add(false);
      return false;
    }
  }

  /// 通过设备对象连接
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      await device.connect(timeout: const Duration(seconds: 10));

      final services = await device.discoverServices();

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            _sensorCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);

            characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                _parseSensorData(value);
              }
            });
            break;
          }
        }
      }

      _connectionStateController.add(true);
      return true;
    } catch (e) {
      _connectedDevice = null;
      _connectionStateController.add(false);
      return false;
    }
  }

  /// 解析 BLE 传感器数据
  void _parseSensorData(List<int> data) {
    if (data.length < 12) return;

    final buffer = ByteData.sublistView(Uint8List.fromList(data));

    double readShort(int offset) {
      return buffer.getInt16(offset, Endian.little) / 1000.0;
    }

    _sensorDataController.add({
      'accelX': readShort(0),
      'accelY': readShort(2),
      'accelZ': readShort(4),
      'gyroX': readShort(6),
      'gyroY': readShort(8),
      'gyroZ': readShort(10),
    });
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_sensorCharacteristic != null) {
      await _sensorCharacteristic!.setNotifyValue(false);
    }
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectedDevice = null;
    _sensorCharacteristic = null;
    _connectionStateController.add(false);
  }

  void dispose() {
    _connectionStateController.close();
    _sensorDataController.close();
    _deviceScanController.close();
  }
}
