import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/device/device_bloc.dart';

/// 设备扫描与连接页面
class DeviceScanPage extends StatefulWidget {
  const DeviceScanPage({super.key});

  @override
  State<DeviceScanPage> createState() => _DeviceScanPageState();
}

class _DeviceScanPageState extends State<DeviceScanPage> {
  @override
  void initState() {
    super.initState();
    // 自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceBloc>().add(const StartScan());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) {
          if (state.isConnected) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('设备连接成功'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // 已连接设备
              if (state.isConnected) _buildConnectedSection(context, state),

              // 扫描中提示
              if (state.isScanning)
                const LinearProgressIndicator(),

              // 扫描控制
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: state.isScanning
                            ? null
                            : () => context
                                .read<DeviceBloc>()
                                .add(const StartScan()),
                        icon: const Icon(Icons.bluetooth_searching),
                        label: Text(state.isScanning ? '扫描中...' : '开始扫描'),
                      ),
                    ),
                    if (state.isScanning) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => context
                            .read<DeviceBloc>()
                            .add(const StopScan()),
                        child: const Text('停止'),
                      ),
                    ],
                  ],
                ),
              ),

              // 错误提示
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(state.error!,
                                  style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ),
                ),

              // 设备列表
              Expanded(
                child: state.scannedDevices.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.scannedDevices.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final device = state.scannedDevices[index];
                          return _DeviceTile(
                            name: device['name'] as String,
                            id: device['id'] as String,
                            rssi: device['rssi'] as int,
                            onTap: () {
                              context.read<DeviceBloc>().add(
                                    ConnectToDevice(device['id'] as String),
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectedSection(BuildContext context, DeviceState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('已连接',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
                Text(state.connectedDevice?['name'] ?? '',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<DeviceBloc>().add(const DisconnectDevice()),
            child: const Text('断开', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('未发现设备',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('确保可穿戴设备已开启并靠近手机',
              style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final String id;
  final int rssi;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.name,
    required this.id,
    required this.rssi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final signalStrength = (rssi + 100).clamp(0, 60) / 60.0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.watch, color: AppTheme.primaryColor),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(id, style: const TextStyle(fontSize: 11)),
            Row(
              children: [
                Icon(Icons.signal_cellular_alt,
                    size: 14,
                    color: signalStrength > 0.5
                        ? AppTheme.primaryColor
                        : Colors.orange),
                const SizedBox(width: 4),
                Text('${rssi}dBm',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('连接'),
        ),
      ),
    );
  }
}
