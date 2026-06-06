"""通知服务 — 家属推送"""

import json
import logging
from typing import Optional
from dataclasses import dataclass

import requests

from config import config
from analysis_agent import AnalysisResult

logger = logging.getLogger(__name__)


@dataclass
class Notification:
    """通知内容"""
    title: str
    body: str
    severity: str = "info"  # info / warning / alert
    recipient: str = "家属"


class NotificationService:
    """通知服务"""

    def __init__(self):
        self.webhook_url = config.notify_wechat_webhook

    # ── 日推送 ──

    def send_daily_report(self, user_name: str, result: AnalysisResult) -> bool:
        """推送日分析报告"""
        notif = Notification(
            title=f"📋 {user_name} 今日运动报告",
            body=self._format_daily_body(result),
            severity="info",
        )
        return self._dispatch(notif)

    def send_weekly_report(self, user_name: str, result: AnalysisResult) -> bool:
        """推送周趋势报告"""
        severity = "warning" if "需关注" in (result.findings or "") else "info"
        notif = Notification(
            title=f"📊 {user_name} 本周运动趋势",
            body=self._format_weekly_body(result),
            severity=severity,
        )
        return self._dispatch(notif)

    def send_alert(self, user_name: str, message: str) -> bool:
        """推送预警通知"""
        notif = Notification(
            title=f"⚠️ {user_name} 需要关注",
            body=message,
            severity="alert",
        )
        return self._dispatch(notif)

    # ── 内部 ──

    def _dispatch(self, notif: Notification) -> bool:
        """分发通知（目前支持企业微信 webhook，可扩展）"""
        if self.webhook_url:
            return self._wechat_webhook(notif)
        # Fallback: 写日志
        logger.info(f"[通知] {notif.severity.upper()} | {notif.title}\n{notif.body}")
        return True

    def _wechat_webhook(self, notif: Notification) -> bool:
        """企业微信机器人 webhook"""
        color_map = {"info": "info", "warning": "warning", "alert": "red"}
        payload = {
            "msgtype": "markdown",
            "markdown": {
                "content": (
                    f"## {notif.title}\n\n"
                    f"{notif.body}\n\n"
                    f"---\n"
                    f"*ParkinsonMonitor · {notif.severity.upper()}*"
                )
            },
        }
        try:
            resp = requests.post(self.webhook_url, json=payload, timeout=10)
            return resp.status_code == 200
        except requests.RequestException as e:
            logger.warning(f"Webhook 发送失败: {e}")
            return False

    # ── 格式化 ──

    @staticmethod
    def _format_daily_body(result: AnalysisResult) -> str:
        return result.summary or "今日无数据"

    @staticmethod
    def _format_weekly_body(result: AnalysisResult) -> str:
        parts = []
        if result.summary:
            parts.append(result.summary)
        if result.medication_observation:
            parts.append(f"\n{result.medication_observation}")
        return "\n".join(parts)
