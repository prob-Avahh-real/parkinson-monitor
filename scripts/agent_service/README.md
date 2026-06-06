"""
ParkinsonMonitor — Agent 服务部署说明
======================================

## 架构

Agent 服务是独立的 Python 后端，从 Supabase 读取 events/sessions 数据，
调用 DeepSeek API 做分析，生成报告并推送通知。

## 目录结构

agent_service/
├── main.py                   # 主入口 + CLI + 合成数据
├── config.py                 # 配置（环境变量）
├── supabase_client.py        # Supabase 数据读取
├── analysis_agent.py         # LLM 分析 Agent（日分析/周趋势/用药关联）
├── guardrails.py             # 医疗安全 Guardrails
├── notification_service.py   # 通知推送（微信/日志）
├── report_enhancer.py        # 增强版 PDF 报告
└── requirements.txt          # Python 依赖

## 快速开始

### 1. 配置环境变量

cp .env.example .env
# 编辑 .env，填入：
#   SUPABASE_URL=你的 Supabase 项目 URL
#   SUPABASE_SERVICE_KEY=你的 Supabase service_role key
#   DEEPSEEK_API_KEY=你的 DeepSeek API key
#   WECHAT_WEBHOOK=（可选）企业微信机器人 webhook

### 2. 安装依赖

pip install -r requirements.txt

### 3. 生成合成数据（用于验证）

python main.py seed --user test_user_001

### 4. 运行验证

python main.py seed-run --user test_user_001

### 5. 手动执行分析

# 日分析（今天）
python main.py daily --user test_user_001

# 指定日期
python main.py daily --user test_user_001 --date 2026-06-04

# 周分析
python main.py weekly --user test_user_001

# 所有用户
python main.py daily-all

## 定时调度

### 方案 A：系统 cron（推荐）

# 每天 21:00 执行日分析
0 21 * * * cd /path/to/agent_service && python main.py daily-all

# 每周一 08:00 执行周分析
0 8 * * 1 cd /path/to/agent_service && python main.py weekly-all

### 方案 B：Docker + cron

见 Dockerfile

## 安全说明

所有 Agent 输出都经过 guardrails.py 过滤，确保：
1. 不输出诊断结论
2. 不给出药物剂量建议
3. 不包含绝对化断言
4. 每次输出附免责声明

## 费用估算

基于 DeepSeek V4-Pro 定价 ($0.87/百万输出 token)：
- 日分析：~500 tokens → ~$0.0004/用户/天
- 周分析：~1500 tokens → ~$0.0013/用户/周
- 单用户月费：~$0.015 ≈ ¥0.11

远低于 SaaS 订阅价，成本可忽略。
"""
