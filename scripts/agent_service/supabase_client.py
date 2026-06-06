"""Supabase 数据接入层 — 读取 events/sessions 并整理为 LLM 可消费的格式"""

from datetime import datetime, timedelta, date
from typing import Optional
from dataclasses import dataclass

from supabase import create_client, Client
from config import config


# ── 类型映射 ──

EVENT_TYPE_MAP = {0: "步态冻结", 1: "静止性震颤", 2: "运动迟缓", 3: "姿势不稳", 4: "正常"}
SEVERITY_MAP = {0: "轻度", 1: "中度", 2: "重度"}


@dataclass
class EventSummary:
    """单个事件的摘要（供 LLM 消费）"""
    timestamp: str
    event_type: str
    severity: str
    confidence: float
    freeze_index: Optional[float] = None
    tremor_freq: Optional[float] = None
    movement_amp: Optional[float] = None

    @property
    def detail_str(self) -> str:
        parts = [f"{self.event_type}({self.severity})"]
        if self.freeze_index is not None:
            parts.append(f"FI={self.freeze_index:.2f}")
        if self.tremor_freq is not None:
            parts.append(f"{self.tremor_freq:.1f}Hz")
        return " | ".join(parts)


@dataclass
class DailySummary:
    """单日摘要"""
    date: str
    total_events: int
    by_type: dict  # type_name -> count
    by_hour: dict  # hour -> count
    events: list[EventSummary]
    total_distance_m: float
    total_steps: int
    total_duration_min: float
    medication_times: list[str] = None  # 当日用药时间列表

    def to_text(self) -> str:
        lines = [f"📅 {self.date} 监测概览"]
        lines.append(f"    总事件: {self.total_events} 次")
        lines.append(f"    总时长: {self.total_duration_min:.0f} 分钟")
        lines.append(f"    总步数: {self.total_steps} 步 ({self.total_distance_m:.0f} 米)")
        lines.append(f"    按类型: {' | '.join(f'{k}: {v}次' for k, v in self.by_type.items())}")
        if self.by_hour:
            peak = max(self.by_hour, key=self.by_hour.get)
            lines.append(f"    高发时段: {peak}:00 左右 ({self.by_hour[peak]} 次)")
        if self.medication_times:
            times = "、".join(t[-8:-3] for t in self.medication_times)
            lines.append(f"    用药时间: {times}")
        return "\n".join(lines)


@dataclass
class WeeklySummary:
    """周趋势摘要"""
    start_date: str
    end_date: str
    days_active: int
    total_events: int
    daily_breakdown: list[DailySummary]
    daily_fog_counts: list[tuple[str, int]]  # (date, count)

    def to_text(self) -> str:
        lines = [f"📊 {self.start_date} ~ {self.end_date} 周趋势"]
        lines.append(f"    监测天数: {self.days_active}/{self.daily_breakdown_len()}")
        lines.append(f"    总事件: {self.total_events} 次")
        lines.append("    日 FoG 趋势:")
        for d, c in self.daily_fog_counts:
            bar = "█" * min(c, 20)
            lines.append(f"      {d}: {c}次 {bar}")
        return "\n".join(lines)

    def daily_breakdown_len(self) -> int:
        return 7  # 一周


# ── 客户端 ──

class SupabaseReader:
    """从 Supabase 读取患者数据"""

    def __init__(self):
        self.client: Client = create_client(config.supabase_url, config.supabase_key)

    def get_user_name(self, user_id: str) -> str:
        """预留：获取患者姓名（需要扩展 users 表）"""
        return "患者"

    def get_events(
        self, user_id: str, since: datetime, until: Optional[datetime] = None
    ) -> list[dict]:
        """获取时间范围内的所有事件"""
        query = (
            self.client.table("events")
            .select("*")
            .eq("user_id", user_id)
            .gte("timestamp", since.isoformat())
            .order("timestamp")
        )
        if until:
            query = query.lte("timestamp", until.isoformat())
        resp = query.execute()
        return resp.data

    def get_sessions(
        self, user_id: str, since: datetime, until: Optional[datetime] = None
    ) -> list[dict]:
        """获取时间范围内的监测会话"""
        query = (
            self.client.table("sessions")
            .select("*")
            .eq("user_id", user_id)
            .gte("start_time", since.isoformat())
            .order("start_time")
        )
        if until:
            query = query.lte("start_time", until.isoformat())
        resp = query.execute()
        return resp.data

    def get_medications(
        self, user_id: str, since: datetime, until: Optional[datetime] = None
    ) -> list[dict]:
        """获取时间范围内的用药记录"""
        query = (
            self.client.table("medication_records")
            .select("*")
            .eq("user_id", user_id)
            .gte("recorded_at", since.isoformat())
            .order("recorded_at")
        )
        if until:
            query = query.lte("recorded_at", until.isoformat())
        resp = query.execute()
        return resp.data

    def build_daily_summary(self, user_id: str, day: date) -> DailySummary:
        """构建单日摘要"""
        since = datetime(day.year, day.month, day.day, 0, 0, 0)
        until = since + timedelta(days=1)
        events = self.get_events(user_id, since, until)
        sessions = self.get_sessions(user_id, since, until)
        meds = self.get_medications(user_id, since, until)

        # 事件按类型聚合
        by_type: dict[str, int] = {}
        by_hour: dict[str, int] = {}
        event_summaries = []

        for e in events:
            t = e.get("type", 0) if isinstance(e.get("type"), int) else 0
            s = e.get("severity", 0) if isinstance(e.get("severity"), int) else 0
            type_name = EVENT_TYPE_MAP.get(t, "未知")
            severity_name = SEVERITY_MAP.get(s, "未知")

            event_summaries.append(EventSummary(
                timestamp=e.get("timestamp", "")[:16],
                event_type=type_name,
                severity=severity_name,
                confidence=e.get("confidence", 0.0) or 0.0,
                freeze_index=e.get("freeze_index"),
                tremor_freq=e.get("tremor_frequency"),
                movement_amp=e.get("movement_amplitude"),
            ))
            by_type[type_name] = by_type.get(type_name, 0) + 1
            hour = e.get("timestamp", "12:00")[11:13]
            by_hour[hour] = by_hour.get(hour, 0) + 1

        # 会话聚合
        total_dist = sum(s.get("total_distance_meters", 0) or 0 for s in sessions)
        total_steps = sum(s.get("total_steps", 0) or 0 for s in sessions)
        total_min = sum(
            self._duration_min(s) for s in sessions
        )

        return DailySummary(
            date=day.isoformat(),
            total_events=len(events),
            by_type=by_type,
            by_hour=dict(sorted(by_hour.items())),
            events=event_summaries,
            total_distance_m=total_dist,
            total_steps=total_steps,
            total_duration_min=total_min,
            medication_times=[m.get("recorded_at", "") for m in meds],
        )

    def build_weekly_summary(self, user_id: str, start: date, end: date) -> WeeklySummary:
        """构建周摘要"""
        dailies = []
        fog_counts = []
        total = 0
        active_days = 0
        d = start
        while d <= end:
            ds = self.build_daily_summary(user_id, d)
            dailies.append(ds)
            total += ds.total_events
            fog_count = ds.by_type.get("步态冻结", 0)
            fog_counts.append((d.isoformat(), fog_count))
            if ds.total_events > 0:
                active_days += 1
            d += timedelta(days=1)

        return WeeklySummary(
            start_date=start.isoformat(),
            end_date=end.isoformat(),
            days_active=active_days,
            total_events=total,
            daily_breakdown=dailies,
            daily_fog_counts=fog_counts,
        )

    def list_users(self) -> list[str]:
        """获取所有有数据的用户 ID"""
        resp = self.client.table("events").select("user_id").execute()
        return list(set(e["user_id"] for e in resp.data if e.get("user_id")))

    @staticmethod
    def _duration_min(session: dict) -> float:
        start = session.get("start_time")
        end = session.get("end_time")
        if not start or not end:
            return 0
        try:
            s = datetime.fromisoformat(start)
            e = datetime.fromisoformat(end)
            return (e - s).total_seconds() / 60
        except (ValueError, TypeError):
            return 0
