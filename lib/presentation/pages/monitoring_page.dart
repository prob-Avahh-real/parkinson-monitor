import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/monitoring/monitoring_bloc.dart';
import '../../domain/entities/movement_disorder_type.dart';
import '../../domain/entities/detection_event.dart';
// feedback_service used via BLoC listener

/// 实时监测页面
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with TickerProviderStateMixin {
  Timer? _metricsTimer;
  final List<double> _chartData = List.filled(120, 0); // 最近 2 分钟数据
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // 定期更新指标
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final bloc = context.read<MonitoringBloc>();
        // 滚动图表数据
        final reading = bloc.state.latestReading;
        if (reading != null) {
          setState(() {
            _chartData.removeAt(0);
            _chartData.add(reading.accelMagnitude);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _metricsTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MonitoringBloc, MonitoringState>(
      listener: (context, state) {
        // 状态变化时触发脉冲动画
        if (state.status != 'normal') {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('实时监测'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmStop(context),
          ),
          actions: [
            // 模式切换
            BlocBuilder<MonitoringBloc, MonitoringState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.mode == ActivityMode.indoor
                        ? Icons.home
                        : Icons.nature,
                  ),
                  tooltip: state.mode == ActivityMode.indoor ? '室内' : '户外',
                  onPressed: () {},
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<MonitoringBloc, MonitoringState>(
          builder: (context, state) {
            return Column(
              children: [
                // 状态指示器
                _StatusBanner(status: state.status),
                const SizedBox(height: 8),

                // 实时图表
                _RealtimeChart(data: _chartData, status: state.status),
                const SizedBox(height: 8),

                // 指标面板
                _MetricsPanel(state: state),
                const SizedBox(height: 8),

                // 事件列表
                Expanded(
                  child: _EventList(events: state.recentEvents),
                ),

                // 停止按钮
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmStop(context),
                        icon: const Icon(Icons.stop_circle),
                        label: const Text('停止监测',
                            style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('停止监测'),
        content: const Text('确定要停止当前监测会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<MonitoringBloc>().add(const StopMonitoring());
              Navigator.pop(ctx); // dialog
              Navigator.pop(context); // page
            },
            child: const Text('停止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 状态横幅 — 显示当前检测到的异常
class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _statusInfo();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (status != 'normal') ...[
            const SizedBox(width: 8),
            _PulseDot(color: color),
          ],
        ],
      ),
    );
  }

  (String, Color, IconData) _statusInfo() {
    switch (status) {
      case 'fog':
        return ('⚠ 步态冻结', AppTheme.fogColor, Icons.warning_amber);
      case 'tremor':
        return ('⚠ 静止性震颤', AppTheme.tremorColor, Icons.vibration);
      case 'brady':
        return ('⚠ 运动迟缓', AppTheme.bradyColor, Icons.slow_motion_video);
      default:
        return ('● 行走正常', AppTheme.normalColor, Icons.check_circle);
    }
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Container(
          width: 10 + _controller.value * 6,
          height: 10 + _controller.value * 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 1 - _controller.value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// 实时加速度图表
class _RealtimeChart extends StatelessWidget {
  final List<double> data;
  final String status;

  const _RealtimeChart({required this.data, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 3,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  data.length,
                  (i) => FlSpot(i.toDouble(), data[i].clamp(0, 3)),
                ),
                isCurved: true,
                color: AppTheme.statusColor(status),
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.statusColor(status).withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 实时指标面板
class _MetricsPanel extends StatelessWidget {
  final MonitoringState state;

  const _MetricsPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final metrics = state.metrics;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricChip(
            label: '步频',
            value: '${(metrics['cadence'] ?? 0).toStringAsFixed(0)}/min',
            color: AppTheme.infoColor,
          ),
          _MetricChip(
            label: '冻结指数',
            value: (metrics['freezeIndex'] ?? 0).toStringAsFixed(2),
            color: AppTheme.fogColor,
          ),
          _MetricChip(
            label: '震颤频率',
            value: '${(metrics['tremorFreq'] ?? 0).toStringAsFixed(1)} Hz',
            color: AppTheme.tremorColor,
          ),
          _MetricChip(
            label: '振幅',
            value: '${(metrics['amplitude'] ?? 0).toStringAsFixed(2)} g',
            color: AppTheme.bradyColor,
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

/// 事件列表
class _EventList extends StatelessWidget {
  final List<DetectionEvent> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('暂无异常事件',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final DetectionEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _eventInfo();

    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          radius: 18,
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${event.severity.name.toUpperCase()} · ${(event.confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ),
    );
  }

  (String, IconData, Color) _eventInfo() {
    switch (event.type) {
      case MovementDisorderType.freezingOfGait:
        return ('步态冻结', Icons.warning_amber, AppTheme.fogColor);
      case MovementDisorderType.restingTremor:
        return ('静止性震颤', Icons.vibration, AppTheme.tremorColor);
      case MovementDisorderType.bradykinesia:
        return ('运动迟缓', Icons.slow_motion_video, AppTheme.bradyColor);
      default:
        return ('正常', Icons.check, AppTheme.normalColor);
    }
  }
}
