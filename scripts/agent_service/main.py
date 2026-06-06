"""Agent 服务主入口 — 日分析 / 周趋势 / 通知推送调度"""

import argparse
import logging
import os
import sys
from datetime import date, datetime

from config import config
from supabase_client import SupabaseReader
from analysis_agent import AnalysisAgent
from notification_service import NotificationService
from report_enhancer import EnhancedReportGenerator

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("agent")


class AgentOrchestrator:
    """Agent 编排器 — 调度分析 → 生成报告 → 推送通知"""

    def __init__(self):
        self.db = SupabaseReader()
        self.agent = AnalysisAgent()
        self.notifier = NotificationService()
        self.reporter = EnhancedReportGenerator()
        os.makedirs(config.output_dir, exist_ok=True)

    # ── 日分析流程 ──

    def run_daily(self, user_id: str, analysis_date: date | None = None) -> dict:
        """执行日分析全流程"""
        logger.info(f"开始日分析: user={user_id}, date={analysis_date or date.today()}")
        result = self.agent.daily_analysis(user_id, analysis_date or date.today())

        # 推送
        self.notifier.send_daily_report("患者", result)
        logger.info(f"日分析完成: summary_length={len(result.summary)}")
        return {"summary": result.summary, "findings": result.findings}

    # ── 周趋势流程 ──

    def run_weekly(self, user_id: str, end_date: date | None = None) -> dict:
        """执行周趋势全流程"""
        logger.info(f"开始周分析: user={user_id}, week_ending={end_date or date.today()}")

        # 1. LLM 分析
        result = self.agent.weekly_trend(user_id, end_date)

        # 2. 用药关联
        med_obs = self.agent.medication_correlation(user_id)

        # 3. PDF 报告
        try:
            pdf_bytes = self.reporter.generate_weekly_pdf(user_id, end_date=end_date)
            pdf_path = os.path.join(
                config.output_dir,
                f"weekly_{user_id[:8]}_{(end_date or date.today()).isoformat()}.pdf",
            )
            with open(pdf_path, "wb") as f:
                f.write(pdf_bytes)
            logger.info(f"PDF 报告已生成: {pdf_path}")
        except Exception as e:
            logger.warning(f"PDF 生成失败 (可忽略): {e}")
            pdf_path = None

        # 4. 推送
        self.notifier.send_weekly_report("患者", result)

        return {
            "summary": result.summary,
            "findings": result.findings,
            "recommendation": result.recommendation,
            "medication_observation": med_obs,
            "pdf_path": pdf_path,
        }

    # ── 为所有用户执行 ──

    def run_daily_all(self):
        """为所有活跃用户执行日分析"""
        users = self.db.list_users()
        logger.info(f"日分析: 发现 {len(users)} 位活跃用户")
        for uid in users:
            try:
                self.run_daily(uid)
            except Exception as e:
                logger.error(f"用户 {uid[:8]} 分析失败: {e}")

    def run_weekly_all(self):
        """为所有活跃用户执行周分析"""
        users = self.db.list_users()
        logger.info(f"周分析: 发现 {len(users)} 位活跃用户")
        for uid in users:
            try:
                self.run_weekly(uid)
            except Exception as e:
                logger.error(f"用户 {uid[:8]} 周分析失败: {e}")


# ── 合成数据生成（用于测试验证） ──

def generate_synthetic_data(user_id: str = "test_user_001"):
    """生成合成数据用于全流程验证"""
    from supabase import create_client
    import random
    import json
    from uuid import uuid4

    supabase = create_client(config.supabase_url, config.supabase_key)

    # 生成最近 7 天的数据
    for day_offset in range(7):
        d = date.today()
        base = datetime(d.year, d.month, d.day, 8, 0, 0)
        session_id = str(uuid4())

        # 每天 8:00 ~ 10:00 的监测
        start = base.replace(hour=8, minute=random.randint(0, 59))
        end = base.replace(hour=10, minute=random.randint(0, 59))

        # 每天随机 2-8 个事件
        events = []
        for _ in range(random.randint(2, 8)):
            event_time = base.replace(
                hour=random.randint(8, 17),
                minute=random.randint(0, 59),
            )
            event_type = random.choices(
                [0, 1, 2],
                weights=[0.5, 0.3, 0.2],  # FOG:50%, 震颤:30%, 运动迟缓:20%
                k=1,
            )[0]
            events.append({
                "id": str(uuid4()),
                "session_id": session_id,
                "user_id": user_id,
                "timestamp": event_time.isoformat(),
                "type": event_type,
                "severity": random.choice([0, 1, 2]),
                "confidence": round(random.uniform(0.7, 0.99), 2),
                "freeze_index": round(random.uniform(1.5, 5.0), 2) if event_type == 0 else None,
                "tremor_frequency": round(random.uniform(4.0, 6.0), 1) if event_type == 1 else None,
                "movement_amplitude": round(random.uniform(0.05, 0.2), 3) if event_type == 2 else None,
            })

        # 写入 Supabase
        session = {
            "id": session_id,
            "user_id": user_id,
            "start_time": start.isoformat(),
            "end_time": end.isoformat(),
            "mode": 0,
            "events": json.dumps(events),
            "total_distance_meters": round(random.uniform(200, 1500), 1),
            "total_steps": random.randint(300, 3000),
            "gps_path": "[]",
        }
        supabase.table("sessions").upsert(session).execute()
        for evt in events:
            supabase.table("events").upsert(evt).execute()

    logger.info(f"合成数据已生成: user={user_id}, 7天")


# ── CLI ──

def main():
    parser = argparse.ArgumentParser(description="ParkinsonMonitor Agent 服务")
    parser.add_argument("command", choices=["daily", "weekly", "daily-all", "weekly-all", "seed", "seed-run"])
    parser.add_argument("--user", default="test_user_001", help="用户 ID")
    parser.add_argument("--date", help="分析日期 (YYYY-MM-DD)")

    args = parser.parse_args()
    orch = AgentOrchestrator()

    if args.command == "daily":
        d = date.fromisoformat(args.date) if args.date else date.today()
        orch.run_daily(args.user, d)

    elif args.command == "weekly":
        d = date.fromisoformat(args.date) if args.date else date.today()
        result = orch.run_weekly(args.user, d)
        logger.info(f"周分析汇总:\n{result['summary'][:200]}...\n")
        if result.get("pdf_path"):
            logger.info(f"PDF: {result['pdf_path']}")

    elif args.command == "daily-all":
        orch.run_daily_all()

    elif args.command == "weekly-all":
        orch.run_weekly_all()

    elif args.command == "seed":
        generate_synthetic_data(args.user)

    elif args.command == "seed-run":
        logger.info("生成合成数据并运行全流程验证...")
        generate_synthetic_data(args.user)
        orch.run_daily(args.user)
        result = orch.run_weekly(args.user)
        logger.info(f"全流程验证完成")
        logger.info(f"周分析摘要: {result['summary'][:100]}...")
        if result.get("pdf_path"):
            logger.info(f"PDF 路径: {result['pdf_path']}")


if __name__ == "__main__":
    main()
