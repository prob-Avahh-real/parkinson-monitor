import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/medication_service.dart';

/// 用药记录页 — 记录用药时间 + 查看历史
class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final _service = GetIt.instance<MedicationService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = _service.getRecent(count: 30);
    final hasTaken = _service.hasTakenToday;
    final timeText = _service.timeSinceLastText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('用药记录'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 当前状态卡片 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    hasTaken ? Icons.check_circle : Icons.access_time,
                    size: 48,
                    color: hasTaken ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasTaken ? '今日已用药' : '今日尚未记录',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (hasTaken) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _recordMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('记录用药'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 用药建议提示 ──
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '记录用药时间有助于分析"药物-症状"的时序关联。'
                      'Agent 会根据你的用药规律自动生成观察报告。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 历史记录 ──
          Text('最近记录', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '暂无记录\n点击上方按钮开始记录',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            )
          else
            ...records.map((r) => ListTile(
                  leading: const Icon(Icons.medication, color: Colors.green),
                  title: Text(
                    '${r.recordedAt.hour.toString().padLeft(2, '0')}:'
                    '${r.recordedAt.minute.toString().padLeft(2, '0')}  '
                    '${r.medicationName}',
                  ),
                  subtitle: r.dosageMg != null
                      ? Text('${r.dosageMg!.toStringAsFixed(0)}mg')
                      : null,
                  dense: true,
                )),
        ],
      ),
    );
  }

  Future<void> _recordMedication() async {
    // 快速记录，默认药物名称
    await _service.record(medicationName: '左旋多巴');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已记录用药时间'),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {});
    }
  }
}
