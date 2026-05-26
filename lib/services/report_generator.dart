import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/monitoring_session.dart';
import '../domain/entities/detection_event.dart';
import '../domain/entities/movement_disorder_type.dart';

/// 生成 PDF 医疗报告
class ReportGenerator {
  static const _headerColor = PdfColor.fromInt(0xFF2E7D32);
  static const _fogColor = PdfColor.fromInt(0xFFD32F2F);
  static const _tremorColor = PdfColor.fromInt(0xFFFF6F00);
  static const _bradyColor = PdfColor.fromInt(0xFFFDD835);

  /// 生成单次会话的 PDF 报告
  static Future<pw.Document> generateSessionReport(
    MonitoringSession session, {
    String? patientName,
    String? notes,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(session),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // 标题
          pw.Header(
            level: 0,
            text: '帕金森运动障碍监测报告',
            textStyle: pw.TextStyle(
              color: _headerColor,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),

          // 患者信息
          if (patientName != null) ...[
            pw.Text('患者: $patientName',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 4),
          ],
          pw.Text('会话 ID: ${session.id}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 20),

          // 会话概览
          _buildSection('会话概览'),
          _buildInfoRow('开始时间', dateFmt.format(session.startTime)),
          _buildInfoRow('结束时间',
              session.endTime != null ? dateFmt.format(session.endTime!) : '进行中'),
          _buildInfoRow('持续时间', _formatDuration(session.duration)),
          _buildInfoRow('模式', session.mode == ActivityMode.indoor ? '室内' : '户外'),
          _buildInfoRow('总距离', '${session.totalDistanceMeters.toStringAsFixed(0)} 米'),
          _buildInfoRow('总步数', '${session.totalSteps}'),
          pw.SizedBox(height: 20),

          // 事件统计
          _buildSection('运动障碍事件统计'),
          _buildStatTable(session),
          pw.SizedBox(height: 20),

          // 事件详情
          if (session.events.isNotEmpty) ...[
            _buildSection('事件详情'),
            _buildEventTable(session.events),
          ],

          // 趋势总结
          pw.SizedBox(height: 20),
          _buildSection('分析与建议'),
          _buildAnalysis(session),

          // 备注
          if (notes != null) ...[
            pw.SizedBox(height: 20),
            _buildSection('备注'),
            pw.Text(notes, style: const pw.TextStyle(fontSize: 12)),
          ],

          // 免责声明
          pw.SizedBox(height: 30),
          pw.Text(
            '⚠ 本报告由 ParkinsonMonitor 自动生成，仅供辅助参考，不构成医疗诊断。请咨询专业医生获取准确的医疗建议。',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  /// 生成多日趋势报告
  static Future<pw.Document> generateTrendReport(
    List<MonitoringSession> sessions, {
    String? patientName,
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd');

    // 聚合统计
    int totalFog = 0, totalTremor = 0, totalBrady = 0;
    double totalDist = 0;
    Duration totalDur = Duration.zero;
    for (final s in sessions) {
      totalFog += s.fogCount;
      totalTremor += s.tremorCount;
      totalBrady += s.bradykinesiaCount;
      totalDist += s.totalDistanceMeters;
      totalDur += s.duration;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(sessions.isNotEmpty ? sessions.first : null),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.Header(
            level: 0,
            text: '帕金森运动障碍趋势报告',
            textStyle: pw.TextStyle(
              color: _headerColor,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('周期: ${dateFmt.format(from)} — ${dateFmt.format(to)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          pw.SizedBox(height: 20),

          if (patientName != null) ...[
            pw.Text('患者: $patientName',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 16),
          ],

          _buildSection('周期统计'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerCellDecoration:
                const pw.BoxDecoration(color: _headerColor),
            cellAlignment: pw.Alignment.center,
            data: <List<String>>[
              ['指标', '数值'],
              ['监测次数', '${sessions.length}'],
              ['总时长', _formatDuration(totalDur)],
              ['总距离', '${totalDist.toStringAsFixed(0)} 米'],
              ['步态冻结事件', '$totalFog'],
              ['静止性震颤事件', '$totalTremor'],
              ['运动迟缓事件', '$totalBrady'],
              ['日均 FoG', sessions.isEmpty ? '0' : (totalFog / sessions.length).toStringAsFixed(1)],
            ],
          ),
          pw.SizedBox(height: 20),

          _buildSection('每日摘要'),
          ...sessions.map((s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 90,
                      child: pw.Text(dateFmt.format(s.startTime),
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Text('FoG:${s.fogCount} ', style: const pw.TextStyle(fontSize: 10, color: _fogColor)),
                    pw.Text('震颤:${s.tremorCount} ', style: const pw.TextStyle(fontSize: 10, color: _tremorColor)),
                    pw.Text('迟缓:${s.bradykinesiaCount}', style: const pw.TextStyle(fontSize: 10, color: _bradyColor)),
                  ],
                ),
              )),

          pw.SizedBox(height: 30),
          pw.Text(
            '⚠ 本报告由 ParkinsonMonitor 自动生成，仅供辅助参考，不构成医疗诊断。',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  /// 保存 PDF 到本地文件
  static Future<String> saveToFile(pw.Document doc, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  /// 分享/打印 PDF
  static Future<void> shareOrPrint(pw.Document doc) async {
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  // ── 内部构建方法 ──

  static pw.Widget _buildHeader(MonitoringSession? session) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Parkinson Monitor',
              style: pw.TextStyle(
                color: _headerColor,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        '第 ${context.pageNumber} 页 / 共 ${context.pagesCount} 页 | ParkinsonMonitor v1.0',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _buildSection(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: _headerColor,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatTable(MonitoringSession session) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerCellDecoration: const pw.BoxDecoration(color: _headerColor),
      cellAlignment: pw.Alignment.center,
      data: <List<String>>[
        ['事件类型', '次数', '严重程度分布'],
        [
          '步态冻结 (FoG)',
          '${session.fogCount}',
          _severityDist(session.events, MovementDisorderType.freezingOfGait),
        ],
        [
          '静止性震颤',
          '${session.tremorCount}',
          _severityDist(session.events, MovementDisorderType.restingTremor),
        ],
        [
          '运动迟缓',
          '${session.bradykinesiaCount}',
          _severityDist(session.events, MovementDisorderType.bradykinesia),
        ],
      ],
    );
  }

  static String _severityDist(
      List<DetectionEvent> events, MovementDisorderType type) {
    final filtered = events.where((e) => e.type == type).toList();
    if (filtered.isEmpty) return '-';
    final mild = filtered.where((e) => e.severity == Severity.mild).length;
    final mod = filtered.where((e) => e.severity == Severity.moderate).length;
    final sev = filtered.where((e) => e.severity == Severity.severe).length;
    return '轻:$mild 中:$mod 重:$sev';
  }

  static pw.Widget _buildEventTable(List<DetectionEvent> events) {
    final rows = <List<String>>[
      ['时间', '类型', '严重程度', '置信度', '详情'],
    ];
    for (final event in events.take(30)) {
      // 限制 30 条以免页面溢出
      String details = '';
      if (event.freezeIndex != null) {
        details = 'FI:${event.freezeIndex!.toStringAsFixed(2)}';
      } else if (event.tremorFrequency != null) {
        details = '${event.tremorFrequency!.toStringAsFixed(1)}Hz';
      } else if (event.movementAmplitude != null) {
        details = 'Amp:${event.movementAmplitude!.toStringAsFixed(2)}';
      }

      String typeLabel;
      switch (event.type) {
        case MovementDisorderType.freezingOfGait:
          typeLabel = '步态冻结';
        case MovementDisorderType.restingTremor:
          typeLabel = '静止性震颤';
        case MovementDisorderType.bradykinesia:
          typeLabel = '运动迟缓';
        default:
          typeLabel = '正常';
      }

      rows.add([
        DateFormat('HH:mm:ss').format(event.timestamp),
        typeLabel,
        event.severity.name.toUpperCase(),
        '${(event.confidence * 100).toStringAsFixed(0)}%',
        details,
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerCellDecoration: const pw.BoxDecoration(color: _headerColor),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 9),
      data: rows,
    );
  }

  static pw.Widget _buildAnalysis(MonitoringSession session) {
    final buf = StringBuffer();

    if (session.fogCount > 0) {
      buf.writeln('• 检测到 ${session.fogCount} 次步态冻结事件，建议关注起步困难和转身时的表现。');
    }
    if (session.tremorCount > 0) {
      buf.writeln('• 检测到 ${session.tremorCount} 次静止性震颤事件，可能提示多巴胺能药物效果波动。');
    }
    if (session.bradykinesiaCount > 0) {
      buf.writeln('• 检测到 ${session.bradykinesiaCount} 次运动迟缓事件，建议评估运动量和药物方案。');
    }
    if (session.fogCount == 0 && session.tremorCount == 0 && session.bradykinesiaCount == 0) {
      buf.writeln('• 本次监测未检测到明显运动障碍事件，状态良好。');
    }
    buf.writeln('• 建议将此报告与医生分享，以便进行更精准的治疗调整。');

    return pw.Text(buf.toString(), style: const pw.TextStyle(fontSize: 11));
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours 小时 $minutes 分钟';
    return '$minutes 分钟';
  }
}
