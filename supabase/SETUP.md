# Agent 层部署与配置指南

## 前置条件

- [Supabase CLI](https://supabase.com/docs/guides/cli) 已安装
- 你的 Supabase 项目已创建
- 已有的 `events` 和 `sessions` 表（从你 App 的 Supabase 配置继承）

---

## 第一步：部署数据库表

在 Supabase 控制台的 SQL 编辑器中执行 `migrations/004_analysis_tables.sql`。

或者通过 CLI：

```bash
supabase db push
```

这会创建以下新表：
- `analysis_results` — 日/周分析结果存储
- `alert_flags` — 异常标记
- `notifications` — 通知（供家属端读取）

---

## 第二步：获取 DeepSeek API Key

1. 访问 https://platform.deepseek.com/ 注册账号
2. 进入 API Keys 页面 → 创建新的 API Key
3. 充值（DeepSeek V4-Pro 输出 $0.87/百万 token，日分析每次约 200 tokens，周分析约 800 tokens，单用户月成本约 ¥1-2）

## 第三步：配置环境变量

```bash
# 登录 Supabase
supabase login

# 关联项目
supabase link --project-ref YOUR_PROJECT_REF

# 设置 DeepSeek API Key
supabase secrets set DEEPSEEK_API_KEY=sk-your-deepseek-api-key-here
```

---

## 第四步：部署 Edge Functions

```bash
# 部署日分析函数
supabase functions deploy daily-analysis

# 部署周分析函数
supabase functions deploy weekly-analysis

# 验证部署
supabase functions list
```

---

## 第五步：配置定时任务

### 方式 A：通过 Supabase Dashboard（推荐）

1. 打开 Supabase 控制台 → SQL 编辑器
2. 执行以下 SQL（替换 YOUR_PROJECT_REF 和 YOUR_SERVICE_ROLE_KEY）：

```sql
-- 启用 pg_cron 扩展（如未启用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 创建日分析定时任务（每天 21:00）
SELECT cron.schedule(
  'daily-analysis',
  '0 21 * * *',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/daily-analysis',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'
  )
  $$
);

-- 创建周分析定时任务（每周日 21:00）
SELECT cron.schedule(
  'weekly-analysis',
  '0 21 * * 0',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/weekly-analysis',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'
  )
  $$
);
```

### 方式 B：通过 Flutter App 触发

如果你的 App 有后台运行能力，也可以在 App 内触发：

```dart
// 在 App 启动时检查是否到了分析时间
// 调用 Supabase Function
final response = await supabase.functions.invoke('daily-analysis');
```

---

## 第六步：验证运行

手动测试 Edge Function：

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/daily-analysis \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

预期响应：

```json
{
  "message": "日分析完成",
  "date": "2026-06-04",
  "total": 3,
  "processed": 3
}
```

---

## 第七步：查看分析结果

在 Supabase 控制台 → Table Editor 中查看 `analysis_results` 表：

```sql
-- 查看最新的分析结果
SELECT 
  user_id, 
  analysis_type, 
  period_start, 
  summary->>'summary' AS short_summary,
  summary->>'alertType' AS alert,
  created_at
FROM analysis_results
ORDER BY created_at DESC
LIMIT 20;
```

---

## 第八步：对接微信小程序

### 家属端小程序需要做什么

1. **连接 Supabase** — 使用 Supabase 的 JS 客户端库（`@supabase/supabase-js`）直接读取 `notifications` 表
2. **展示通知列表** — 从 `notifications` 表读取通知，按 `created_at` 倒序
3. **展示周报** — 从 `analysis_results` 表读取 `analysis_type = 'weekly'` 的结果
4. **订阅推送** — 使用微信小程序的订阅消息模板

### 简化方案（不需要额外写后端）

```javascript
// 微信小程序中读取通知
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// 获取用户未读通知
async function getNotifications(userId) {
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(20)
  return { data, error }
}

// 获取最新周报
async function getLatestWeeklyReport(userId) {
  const { data, error } = await supabase
    .from('analysis_results')
    .select('summary')
    .eq('user_id', userId)
    .eq('analysis_type', 'weekly')
    .order('period_end', { ascending: false })
    .limit(1)
  return data?.[0]?.summary || null
}
```

> 注意：微信小程序需要登录后绑定 `user_id`。最简单的绑定方式：患者 App 生成一个分享码/二维码，家属微信小程序扫码后建立关联。关联关系可存为 `family_bindings` 表（非必须，初期可简化）。

---

## 成本估算

| 项目 | 月成本 | 说明 |
|------|--------|------|
| DeepSeek V4-Pro 日分析 | ~¥0.90/用户 | 每天 1 次，每次 ~200 tokens |
| DeepSeek V4-Pro 周分析 | ~¥0.30/用户 | 每周 1 次，每次 ~800 tokens |
| Supabase 免费额度 | ¥0 | 足够覆盖 100 用户以下 |
| Edge Functions 执行 | ¥0 | 免费额度内 |
| **合计** | **~¥1.2/用户/月** | |

---

## 安全注意事项

1. **Service Role Key 不要泄露** — 只用于 Edge Functions 后台调用
2. **微信小程序使用 Anon Key** + RLS 策略保护数据
3. **所有 LLM 输出经过 guardrails 过滤** — 详见 `_shared/guardrails.ts`
4. **建议定期审查分析结果** — 确保 AI 输出质量
