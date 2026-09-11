import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/calibration_service.dart';
import '../../services/report_generator.dart';
import '../../services/gmi_cloud_service.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../core/di/injection_container.dart' as di;

/// 设置页面 — 含校准功能
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box _settingsBox;
  bool _audioFeedback = true;
  bool _vibrationFeedback = true;
  double _fogThreshold = 1.8;
  int _sampleRate = 50;
  bool _isCalibrated = false;
  String? _calibrationDate;

  final _calibrationService = di.sl<CalibrationService>();
  final _gmiCloudService = di.sl<GmiCloudService>();
  bool _isCalibrating = false;
  double _calibProgress = 0;
  StreamSubscription? _calibSub;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(AppConstants.settingsBox);
    _loadSettings();
  }

  @override
  void dispose() {
    _calibSub?.cancel();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _audioFeedback = _settingsBox.get(AppConstants.keyAudioFeedback,
          defaultValue: true);
      _vibrationFeedback = _settingsBox.get(AppConstants.keyVibrationFeedback,
          defaultValue: true);
      _fogThreshold = _settingsBox
          .get(AppConstants.keyFogThreshold, defaultValue: 1.8)
          .toDouble();
      _sampleRate =
          _settingsBox.get(AppConstants.keySampleRate, defaultValue: 50);
      _isCalibrated =
          _settingsBox.get('calibrated', defaultValue: false);
      _calibrationDate = _settingsBox.get('calibration_date');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 反馈设置
          _sectionHeader('反馈设置'),
          SwitchListTile(
            title: const Text('声音提示'),
            subtitle: const Text('检测到异常时播放提示音'),
            secondary: const Icon(Icons.volume_up),
            value: _audioFeedback,
            onChanged: (v) {
              setState(() => _audioFeedback = v);
              _settingsBox.put(AppConstants.keyAudioFeedback, v);
            },
          ),
          SwitchListTile(
            title: const Text('振动提示'),
            subtitle: const Text('检测到异常时振动提醒'),
            secondary: const Icon(Icons.vibration),
            value: _vibrationFeedback,
            onChanged: (v) {
              setState(() => _vibrationFeedback = v);
              _settingsBox.put(AppConstants.keyVibrationFeedback, v);
            },
          ),
          const Divider(),

          // 传感器校准
          _sectionHeader('传感器校准'),
          _buildCalibrationCard(),
          const Divider(),

          // 检测参数
          _sectionHeader('检测参数'),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('步态冻结阈值'),
            subtitle: Text('当前: ${_fogThreshold.toStringAsFixed(1)}'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _fogThreshold,
                min: 1.0,
                max: 3.0,
                divisions: 20,
                label: _fogThreshold.toStringAsFixed(1),
                onChanged: (v) {
                  setState(() => _fogThreshold = v);
                  _settingsBox.put(AppConstants.keyFogThreshold, v);
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('采样频率'),
            subtitle: Text('当前: $_sampleRate Hz'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: _sampleRate.toDouble(),
                min: 20,
                max: 100,
                divisions: 8,
                label: '$_sampleRate Hz',
                onChanged: (v) {
                  setState(() => _sampleRate = v.round());
                  _settingsBox.put(AppConstants.keySampleRate, v.round());
                },
              ),
            ),
          ),
          const Divider(),

          // 数据管理
          _sectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Supabase 云端同步'),
            subtitle: const Text('上传监测数据到云端'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _setupCloudSync(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_done),
            title: const Text('GMI Cloud 连接测试'),
            subtitle: const Text('发起 GMI Cloud 状态请求'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => _testGmiCloudConnection(context),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('导出 PDF 报告'),
            subtitle: const Text('生成医疗报告给医生'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportReport(context),
          ),
          const Divider(),

          // 关于
          _sectionHeader('关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('使用说明'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInstructions(context),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: const Text('医疗免责声明'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDisclaimer(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCalibrated ? Icons.check_circle : Icons.sensors,
                  color: _isCalibrated
                      ? AppTheme.primaryColor
                      : AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCalibrated ? '已校准' : '未校准',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isCalibrated
                        ? AppTheme.primaryColor
                        : AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            if (_calibrationDate != null) ...[
              const SizedBox(height: 4),
              Text('校准日期: $_calibrationDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            const SizedBox(height: 8),
            Text(
              '佩戴设备正常行走 6 秒，系统将自动计算个性化阈值。',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            if (_isCalibrating)
              Column(
                children: [
                  LinearProgressIndicator(value: _calibProgress),
                  const SizedBox(height: 8),
                  Text('校准中... ${(_calibProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12)),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _startCalibration,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(_isCalibrated ? '重新校准' : '开始校准'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibProgress = 0;
    });
    _calibrationService.startCalibration();

    // 模拟进度更新 (实际使用时订阅传感器数据)
    _calibSub?.cancel();
    _calibSub = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
      if (!mounted) return;
      setState(() {
        _calibProgress = _calibrationService.progress;
      });
      if (!_calibrationService.isCalibrating) {
        _finishCalibration();
      }
    });
  }

  Future<void> _finishCalibration() async {
    _calibSub?.cancel();
    final result = _calibrationService.finishCalibration();
    await _calibrationService.saveCalibration(result);

    setState(() {
      _isCalibrating = false;
      _fogThreshold = result.fogThreshold;
      _isCalibrated = true;
      _calibrationDate = DateTime.now().toString().substring(0, 16);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '校准完成！FoG 阈值: ${result.fogThreshold.toStringAsFixed(2)}, '
            '震颤: ${result.tremorPowerThreshold.toStringAsFixed(2)}, '
            '迟缓: ${result.bradyAmplitudeThreshold.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  void _setupCloudSync(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('云端同步设置'),
        content: const Text(
          '请在 Supabase 控制台创建项目，获取 URL 和 anon key。\n\n'
          '然后在 main.dart 中调用:\n'
          'SupabaseSyncService.initialize(url: "...", anonKey: "...")\n\n'
          '如果你的云服务使用 GMI Cloud，请把 API key 作为 Dart define 传入:\n'
          'flutter run --dart-define=GMI_CLOUD_API_KEY=your_key\n\n'
          '在 CI 中请将该 key 作为 secret 注入，然后通过 --dart-define 传递。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(BuildContext context) async {
    // 示例：从 AnalyticsRepository 获取最近会话
    try {
      final repo = di.sl<AnalyticsRepository>();
      final sessions = await repo.getSessions(limit: 1);
      if (sessions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂无监测数据可导出')),
          );
        }
        return;
      }

      final doc = await ReportGenerator.generateSessionReport(
        sessions.first,
        patientName: '患者',
      );

      await ReportGenerator.shareOrPrint(doc);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _testGmiCloudConnection(BuildContext context) async {
    if (!_gmiCloudService.isConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GMI Cloud 未配置，请通过 Dart define 提供 API key 和 Base URL。',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在测试 GMI Cloud 连接...')),
      );
    }

    try {
      final status = await _gmiCloudService.fetchStatus();
      if (!mounted) return;

      final message = status == null
          ? 'GMI Cloud 请求失败，未返回有效状态。'
          : 'GMI Cloud 连接成功：${status.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GMI Cloud 请求失败：$e')),
      );
    }
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('使用说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 传感器校准',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('首次使用前，请在设置中点击"开始校准"，佩戴设备正常行走 6 秒。\n'),
              Text('2. 连接设备',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('打开可穿戴设备蓝牙，在"设备管理"中扫描并连接。\n'),
              Text('3. 选择模式',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('室内模式适合居家行走，户外模式会记录 GPS 轨迹。\n'),
              Text('4. 开始监测',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('点击"开始监测"，保持正常行走。\n'),
              Text('5. 导出报告',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('在设置中点击"导出 PDF 报告"，可生成医疗报告分享给医生。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('医疗免责声明'),
        content: const SingleChildScrollView(
          child: Text(
            'ParkinsonMonitor 是一款辅助监测工具，旨在帮助帕金森综合征患者及其护理人员追踪运动症状。\n\n'
            '⚠️ 重要提示：\n'
            '• 本应用不提供医疗诊断，不能替代专业医疗评估\n'
            '• 检测结果仅供参考，不应作为用药或治疗决策的依据\n'
            '• 如有任何健康问题，请及时咨询专业医生\n'
            '• 应用数据默认存储在本地，可选择上传到 Supabase 云端\n\n'
            '使用本应用即表示您已理解并同意以上条款。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我已知晓'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
