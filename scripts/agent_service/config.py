"""Agent 服务配置"""

import os
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Config:
    # Supabase
    supabase_url: str = os.getenv("SUPABASE_URL", "")
    supabase_key: str = os.getenv("SUPABASE_SERVICE_KEY", "")

    # DeepSeek
    deepseek_api_key: str = os.getenv("DEEPSEEK_API_KEY", "")
    deepseek_model: str = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")  # V4-Pro

    # 分析调度
    daily_analysis_hour: int = 21  # 每晚 9 点跑日分析
    weekly_analysis_day: str = "mon"  # 每周一跑周分析

    # 通知（按需配置）
    notify_wechat_webhook: Optional[str] = os.getenv("WECHAT_WEBHOOK", None)
    notify_email_smtp: Optional[str] = os.getenv("EMAIL_SMTP", None)
    notify_email_from: Optional[str] = os.getenv("EMAIL_FROM", None)
    notify_email_password: Optional[str] = os.getenv("EMAIL_PASSWORD", None)

    # 输出目录
    output_dir: str = os.getenv("OUTPUT_DIR", "./output")

    # 医疗安全 guardrails
    enable_guardrails: bool = True


config = Config()
