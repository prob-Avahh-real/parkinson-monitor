"""报告增强 — 生成带趋势分析和 LLM 建议的 PDF 报告"""

import io
from datetime import date, timedelta
from typing import Optional

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak,
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from analysis_agent import AnalysisAgent
from supabase_client import SupabaseReader


class EnhancedReportGenerator:
    """增强版 PDF 报告生成器"""

    def __init__(self):
        self.agent = AnalysisAgent()
        self.db = SupabaseReader()
        self._styles = None

    def generate_weekly_pdf(
        self,
        user_id: str,
        user_name: str = "患者",
        end_date: Optional[date] = None,
    ) -> bytes:
        """生成带 LLM 分析结论的周趋势 PDF"""
        end_date = end_date or date.today()
        start_date = end_date - timedelta(days=6)

        buf = io.BytesIO()
        doc = SimpleDocTemplate(
            buf,
            pagesize=A4,
            topMargin=2*cm,
            bottomMargin=2*cm,
            leftMargin=2*cm,
            rightMargin=2*cm,
        )

        styles = self._get_styles()
        elements = []

        # ── 封面 ──
        elements.append(Paragraph("帕金森运动障碍周趋势报告", styles["Title"]))
        elements.append(Spacer(1, 6*mm))
        elements.append(Paragraph(f"患者: {user_name}", styles["Normal"]))
        elements.append(Paragraph(f"周期: {start_date.isoformat()} ~ {end_date.isoformat()}", styles["Normal"]))
        elements.append(Paragraph(f"生成时间: {date.today().isoformat()}", styles["Normal"]))
        elements.append(Spacer(1, 12*mm))
        elements.append(HRFlowable(width="100%", color=colors.HexColor("#2E7D32")))
        elements.append(Spacer(1, 6*mm))

        # ── 数据统计 ──
        weekly = self.db.build_weekly_summary(user_id, start_date, end_date)
        elements.append(Paragraph("📊 本周数据统计", styles["Heading2"]))
        elements.append(Spacer(1, 4*mm))

        events_data = [[
            Paragraph("日期", styles["TableHeader"]),
            Paragraph("步态冻结", styles["TableHeader"]),
            Paragraph("震颤", styles["TableHeader"]),
            Paragraph("运动迟缓", styles["TableHeader"]),
            Paragraph("总事件", styles["TableHeader"]),
        ]]
        for ds in weekly.daily_breakdown:
            events_data.append([
                ds.date[-5:],
                str(ds.by_type.get("步态冻结", 0)),
                str(ds.by_type.get("静止性震颤", 0)),
                str(ds.by_type.get("运动迟缓", 0)),
                str(ds.total_events),
            ])
        # 合计行
        events_data.append([
            Paragraph("<b>合计</b>", styles["TableHeader"]),
            Paragraph(f"<b>{sum(ds.by_type.get('步态冻结', 0) for ds in weekly.daily_breakdown)}</b>", styles["TableHeader"]),
            Paragraph(f"<b>{sum(ds.by_type.get('静止性震颤', 0) for ds in weekly.daily_breakdown)}</b>", styles["TableHeader"]),
            Paragraph(f"<b>{sum(ds.by_type.get('运动迟缓', 0) for ds in weekly.daily_breakdown)}</b>", styles["TableHeader"]),
            Paragraph(f"<b>{weekly.total_events}</b>", styles["TableHeader"]),
        ])

        table = Table(events_data, colWidths=[60*mm, 30*mm, 30*mm, 30*mm, 30*mm])
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2E7D32")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("ALIGN", (1, 0), (-1, -1), "CENTER"),
            ("FONTSIZE", (0, 0), (-1, -1), 10),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E8F5E9")),
        ]))
        elements.append(table)

        elements.append(Spacer(1, 8*mm))

        # ── 活动量统计 ──
        total_dist = sum(ds.total_distance_m for ds in weekly.daily_breakdown)
        total_steps = sum(ds.total_steps for ds in weekly.daily_breakdown)
        total_min = sum(ds.total_duration_min for ds in weekly.daily_breakdown)
        elements.append(Paragraph(
            f"本周活动量: {total_steps:.0f} 步 / {total_dist:.0f} 米 / {total_min:.0f} 分钟 "
            f"(日均 {total_steps/7:.0f} 步)",
            styles["Normal"]
        ))
        elements.append(Spacer(1, 8*mm))

        # ── LLM 分析结论 ──
        if weekly.total_events > 0:
            elements.append(HRFlowable(width="100%", color=colors.HexColor("#2E7D32")))
            elements.append(Spacer(1, 4*mm))
            elements.append(Paragraph("🧠 AI 辅助分析", styles["Heading2"]))
            elements.append(Spacer(1, 4*mm))

            result = self.agent.weekly_trend(user_id, start_date)
            for label, content in [
                ("趋势判断", result.summary),
                ("高峰时段", result.findings),
                ("用药观察", result.medication_observation),
                ("康复建议", result.recommendation),
            ]:
                if content:
                    elements.append(Paragraph(f"<b>{label}:</b>", styles["Normal"]))
                    elements.append(Paragraph(content, styles["BodyText"]))
                    elements.append(Spacer(1, 3*mm))

        # ── 免责声明 ──
        elements.append(Spacer(1, 12*mm))
        elements.append(HRFlowable(width="100%", color=colors.HexColor("#CCCCCC")))
        elements.append(Spacer(1, 3*mm))
        elements.append(Paragraph(
            "⚠ 本报告由 ParkinsonMonitor 自动生成，仅供辅助参考，不构成医疗诊断。"
            "所有分析基于监测数据，请咨询专业医生获取准确的医疗建议。",
            styles["Disclaimer"]
        ))

        doc.build(elements)
        return buf.getvalue()

    # ── 内部 ──

    def _get_styles(self):
        if self._styles:
            return self._styles

        styles = getSampleStyleSheet()
        styles.add(ParagraphStyle(
            "TableHeader",
            fontSize=10,
            textColor=colors.white,
            alignment=1,
            fontName="Helvetica-Bold",
        ))
        styles.add(ParagraphStyle(
            "Disclaimer",
            fontSize=8,
            textColor=colors.grey,
            fontName="Helvetica-Oblique",
        ))
        self._styles = styles
        return styles
