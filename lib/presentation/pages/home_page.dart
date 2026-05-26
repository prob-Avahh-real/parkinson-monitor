import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/device/device_bloc.dart';
import '../blocs/monitoring/monitoring_bloc.dart';
import 'device_scan_page.dart';
import 'monitoring_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import '../../domain/entities/movement_disorder_type.dart';

/// 首页 — 仪表盘总览
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, size: 28),
            SizedBox(width: 8),
            Text('Parkinson Monitor'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateTo(context, const SettingsPage()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 设备状态卡片
            _DeviceStatusCard(),
            const SizedBox(height: 16),

            // 今日摘要
            _TodaySummary(),
            const SizedBox(height: 16),

            // 快速开始按钮
            _QuickStartSection(),
            const SizedBox(height: 16),

            // 最近事件
            _RecentEvents(),
            const SizedBox(height: 16),

            // 功能入口
            _FeatureGrid(),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

/// 设备状态卡片
class _DeviceStatusCard extends StatelessWidget {
  String _deviceName(DeviceState state) {
    if (!state.isConnected) return '连接可穿戴设备以开始监测';
    final name = state.connectedDevice?['name'];
    return (name != null && name is String) ? name : '可穿戴设备';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: state.isConnected
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    state.isConnected
                        ? Icons.watch
                        : Icons.watch_off_outlined,
                    color: state.isConnected
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isConnected ? '设备已连接' : '未连接设备',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _deviceName(state),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                if (!state.isConnected)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DeviceScanPage()),
                      );
                    },
                    child: const Text('连接'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      context.read<DeviceBloc>().add(const DisconnectDevice());
                    },
                    child: const Text('断开',
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 今日摘要
class _TodaySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今日摘要',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.timer,
                  label: '监测时长',
                  value: '0 分钟',
                  color: AppTheme.infoColor,
                ),
                _SummaryItem(
                  icon: Icons.warning_amber,
                  label: '步态冻结',
                  value: '0 次',
                  color: AppTheme.fogColor,
                ),
                _SummaryItem(
                  icon: Icons.vibration,
                  label: '震颤',
                  value: '0 次',
                  color: AppTheme.tremorColor,
                ),
                _SummaryItem(
                  icon: Icons.slow_motion_video,
                  label: '运动迟缓',
                  value: '0 次',
                  color: AppTheme.bradyColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }
}

/// 快速开始
class _QuickStartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonitoringBloc, MonitoringState>(
      builder: (context, state) {
        if (state.isMonitoring) {
          return ElevatedButton.icon(
            onPressed: () => _navigateToMonitoring(context),
            icon: const Icon(Icons.monitor_heart),
            label: const Text('查看实时监测'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size.fromHeight(56),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('开始监测',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    icon: Icons.home,
                    label: '室内',
                    subtitle: '居家行走',
                    onTap: () => _startMonitoring(context, ActivityMode.indoor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.nature,
                    label: '户外',
                    subtitle: '户外行走',
                    onTap: () =>
                        _startMonitoring(context, ActivityMode.outdoor),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _startMonitoring(BuildContext context, ActivityMode mode) {
    context.read<MonitoringBloc>().add(StartMonitoring(mode));
    _navigateToMonitoring(context);
  }

  void _navigateToMonitoring(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonitoringPage()),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

/// 最近事件
class _RecentEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最近事件',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 简化：显示占位
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_note,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('开始监测后，运动障碍事件将在此显示',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 功能入口
class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _FeatureCard(
          icon: Icons.history,
          title: '历史记录',
          subtitle: '查看监测历史',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          ),
        ),
        _FeatureCard(
          icon: Icons.bluetooth,
          title: '设备管理',
          subtitle: '连接可穿戴设备',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeviceScanPage()),
          ),
        ),
        _FeatureCard(
          icon: Icons.bar_chart,
          title: '趋势分析',
          subtitle: '症状趋势图表',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryPage()),
          ),
        ),
        _FeatureCard(
          icon: Icons.tune,
          title: '参数设置',
          subtitle: '调整检测阈值',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
