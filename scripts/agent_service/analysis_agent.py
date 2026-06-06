"""分析 Agent 核心 — 调用 DeepSeek API 做日分析、周趋势、用药关联"""

from datetime import date, timedelta
from typing import Optional
from dataclasses import dataclass

from openai import OpenAI

from config import config
from supabase_client import SupabaseReader, DailySummary, WeeklySummary
from guardrails import validate_analysis_output, sanitize_output, attach_disclaimer


# ── 提示词模板 ──

DAILY_ANALYSIS_PROMPT = """你是一位帕金森病康复辅助分析助手。你的任务是基于当天的运动障碍监测数据，生成一份面向患者和家属的日常分析报告。

## 输入数据格式

今日日期: {date}
监测时长: {duration_min} 分钟
总事件: {total_events} 次

事件分布:
{event_breakdown}

高发时段:
{peak_hours}

用药时间:
{medication_times}

## 输出要求

请生成包含以下三个部分的分析：

1. **今日概况**（2-3 句话）：今天运动状态的整体评价，相比基线是否正常。不要做诊断。

2. **发现**（如果适用）：指出值得注意的模式，如特定时间段高发、特定活动关联。如果一切正常则写"今日无明显异常模式"。

3. **建议**（1-2 条）：基于数据的可操作建议，如训练调整、作息建议。不能涉及用药调整。

## 安全规则（必须遵守）
- ❌ 绝对不能做诊断（"确诊""病情为"等）
- ❌ 绝对不能给出药物剂量调整建议
- ❌ 不能使用绝对化表述（"一定""肯定"）
- ✅ 可以描述数据观察到的模式
- ✅ 可以建议康复训练、作息调整
- ✅ 建议"咨询医生"是安全的

请用中文输出，语气温和、鼓励。"""


WEEKLY_TREND_PROMPT = """你是一位帕金森病康复辅助分析助手。你的任务是分析过去一周的运动障碍监测趋势，生成一份面向患者和家属的周报。

## 输入数据: 过去 7 天的逐日摘要

{weekly_data}

## 输出要求

请输出包含以下部分的分析（JSON 格式输出，仅输出 JSON）：

```json
{{
  "summary": "本周整体概述（2-3 句话）",
  "trend": "趋势判断：改善/稳定/波动/需关注，并说明依据",
  "peak_pattern": "本周高发时段/场景分析",
  "medication_observation": "（如有规律）用药与症状波动的时间关联观察",
  "recommendation": "康复训练或生活习惯方面的建议（1-2 条）"
}}
```

## 安全规则（必须遵守）
- ❌ 绝对不能做诊断
- ❌ 绝对不能给出药物剂量调整建议
- ❌ 使用"可能""建议咨询医生"等温和表述
- ✅ 可以指出数据观察到的模式
"""


@dataclass
class AnalysisResult:
    """分析结果"""
    summary: str = ""
    findings: str = ""
    recommendation: str = ""
    medication_observation: str = ""
    raw_output: str = ""


class AnalysisAgent:
    """分析 Agent"""

    def __init__(self):
        self.client = OpenAI(
            api_key=config.deepseek_api_key,
            base_url="https://api.deepseek.com",
        )
        self.db = SupabaseReader()
        self.model = config.deepseek_model

    # ── 日分析 ──

    def daily_analysis(self, user_id: str, day: Optional[date] = None) -> AnalysisResult:
        """执行单日分析"""
        day = day or date.today()
        summary = self.db.build_daily_summary(user_id, day)

        if summary.total_events == 0:
            return AnalysisResult(
                summary=f"📅 {day.isoformat()} 今日无监测数据。建议明日开启监测以获取分析。",
                findings="无",
                recommendation="保持每日监测习惯，建议在固定时间段进行，以便追踪趋势。",
            )

        # 构造 prompt 输入
        event_breakdown = "\n".join(
            f"  - {t}: {c}次" for t, c in sorted(summary.by_type.items())
        )
        peak_hours = self._format_peak_hours(summary.by_hour)
        medication_times = "、".join(summary.medication_times or []) or "未记录"

        prompt = DAILY_ANALYSIS_PROMPT.format(
            date=day.isoformat(),
            duration_min=summary.total_duration_min,
            total_events=summary.total_events,
            event_breakdown=event_breakdown,
            peak_hours=peak_hours,
            medication_times=medication_times,
        )

        # 调用 DeepSeek
        raw = self._call_llm(prompt)

        # 后处理
        result = AnalysisResult(raw_output=raw, summary=raw, findings="", recommendation="")
        result.summary = sanitize_output(raw)
        result.summary = attach_disclaimer(result.summary)

        return result

    # ── 周趋势分析 ──

    def weekly_trend(self, user_id: str, start: Optional[date] = None) -> AnalysisResult:
        """执行周趋势分析"""
        end = date.today()
        start = start or (end - timedelta(days=6))
        weekly = self.db.build_weekly_summary(user_id, start, end)

        if weekly.total_events == 0:
            return AnalysisResult(
                summary=f"📊 {start.isoformat()} ~ {end.isoformat()} 本周无监测数据。",
                findings="无",
                recommendation="建议持续监测以获取有价值的趋势分析。",
            )

        # 构造周数据文本
        weekly_lines = []
        for ds in weekly.daily_breakdown:
            weekly_lines.append(ds.to_text())
        weekly_text = "\n\n".join(weekly_lines)

        prompt = WEEKLY_TREND_PROMPT.format(weekly_data=weekly_text)

        # 调用 LLM
        raw = self._call_llm(prompt, response_format="json")

        # 解析 + 验证
        result = self._parse_weekly_output(raw, weekly)
        return result

    # ── 简单用药关联分析（无需 LLM） ──

    def medication_correlation(self, user_id: str, days: int = 7) -> str:
        """基于事件时序做简单用药关联分析

        这个方法不依赖 LLM，而是直接从数据中提取可观察的规律。
        符合医疗场景的安全要求——只描述数据不归因。
        """
        end = date.today()
        start = end - timedelta(days=days)
        weekly = self.db.build_weekly_summary(user_id, start, end)

        # 统计各小时的事件分布
        hourly = {}
        for ds in weekly.daily_breakdown:
            for h, c in ds.by_hour.items():
                hourly[h] = hourly.get(h, 0) + c

        if not hourly:
            return "数据不足"

        sorted_hours = sorted(hourly.items(), key=lambda x: x[1], reverse=True)
        top3 = sorted_hours[:3]
        peak_str = "、".join(f"{h}:00（{c}次）" for h, c in top3)

        lines = [
            f"⏰ 过去 {days} 天事件高发时段 Top 3：",
            f"    {peak_str}",
            "💡 建议：可将此规律与用药时间对照，在复诊时与医生讨论。",
        ]
        return "\n".join(lines)

    # ── 内部方法 ──

    def _call_llm(self, prompt: str, response_format: str = "text") -> str:
        """调用 DeepSeek API"""
        kwargs = {
            "model": self.model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.3,  # 低温度让输出更稳定
            "max_tokens": 1024,
        }
        if response_format == "json":
            kwargs["response_format"] = {"type": "json_object"}

        resp = self.client.chat.completions.create(**kwargs)
        return resp.choices[0].message.content or ""

    def _parse_weekly_output(self, raw: str, weekly: WeeklySummary) -> AnalysisResult:
        """解析周分析 JSON 输出"""
        import json

        result = AnalysisResult(raw_output=raw)

        try:
            # 尝试提取 JSON（可能被 markdown 包裹）
            if "```json" in raw:
                raw = raw.split("```json")[1].split("```")[0]
            elif "```" in raw:
                raw = raw.split("```")[1].split("```")[0]

            data = json.loads(raw.strip())
            result.summary = data.get("summary", "")
            result.findings = f"趋势: {data.get('trend', '')}\n高峰: {data.get('peak_pattern', '')}"
            result.recommendation = data.get("recommendation", "")
            result.medication_observation = data.get("medication_observation", "")

            # Guardrails
            validated = validate_analysis_output(
                data,
                require_keys=["summary", "trend", "recommendation"],
            )
            result.summary = validated.get("summary", "")
            result.medication_observation = validated.get("medication_observation", "")

        except (json.JSONDecodeError, KeyError) as e:
            # Fallback: 如果解析失败，直接用原始输出
            result.summary = sanitize_output(raw)
            result.summary = attach_disclaimer(raw)

        return result

    @staticmethod
    def _format_peak_hours(by_hour: dict[str, int]) -> str:
        if not by_hour:
            return "数据不足"
        sorted_items = sorted(by_hour.items(), key=lambda x: x[1], reverse=True)
        top = sorted_items[:3]
        return "、".join(f"{h}:00 时段（{c}次）" for h, c in top)
