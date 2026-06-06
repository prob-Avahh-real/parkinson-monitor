"""医疗安全 Guardrails — 所有 Agent 输出必须经过此模块"""

import re
from typing import Optional

# ── 禁止输出的模式 ──

FORBIDDEN_PATTERNS = [
    # 诊断结论
    r"(?i)(确诊|诊断为|患有.*症|病情为)",
    # 药物剂量建议
    r"(?i)(增加.*剂量|减少.*剂量|调整.*药量|服用.*mg|改服|换药)",
    # 绝对性断言
    r"(?i)(一定|肯定|保证|100%|绝对|必然)",
    # 预测未来
    r"(?i)((将会|一定会|预计).*(恶化|好转|加重|改善))",
]


# ── 强制声明 ──

DISCLAIMER = (
    "\n\n⚠ 本报告由 ParkinsonMonitor 自动生成，仅供辅助参考，不构成医疗诊断。\n"
    "所有分析基于监测数据，请咨询专业医生获取准确的医疗建议。\n"
    "如症状加重或出现不适，请及时就医。"
)

MEDICATION_DISCLAIMER = (
    "\n\n⚠ 用药观察仅供参考。药物调整请务必在主治医生指导下进行，切勿自行调药。"
)


# ── 核心函数 ──

def sanitize_output(text: str) -> str:
    """过滤输出中的禁止内容"""
    for pattern in FORBIDDEN_PATTERNS:
        text = re.sub(pattern, "【此处由专业医生判断】", text)
    return text


def attach_disclaimer(text: str, has_medication_ref: bool = False) -> str:
    """附加免责声明"""
    if not text.endswith(DISCLAIMER):
        text += DISCLAIMER
    if has_medication_ref and MEDICATION_DISCLAIMER not in text:
        text += MEDICATION_DISCLAIMER
    return text


class GuardrailError(Exception):
    """Guardrail 阻断异常"""
    pass


def validate_analysis_output(
    output: dict,
    require_keys: Optional[list[str]] = None,
) -> dict:
    """验证分析输出格式和内容安全

    验证规则：
    1. 必须包含免责声明
    2. 禁止出现诊断结论
    3. 禁止出现具体药物剂量建议
    4. 禁止出现绝对性断言
    5. 对用药关联分析必须附加用药声明
    """
    require_keys = require_keys or ["summary", "date"]

    # 检查必填字段
    for k in require_keys:
        if k not in output:
            raise GuardrailError(f"缺少必填字段: {k}")

    # 如果有 medication_observation 字段，标记需要用药声明
    has_med = "medication_observation" in output

    # 清洗所有字符串字段
    for k, v in output.items():
        if isinstance(v, str):
            output[k] = sanitize_output(v)
            output[k] = attach_disclaimer(v, has_medication_ref=has_med)

    return output
