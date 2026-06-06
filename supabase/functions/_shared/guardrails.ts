// ============================================================
// 安全护栏 — LLM 输出的安全约束
// ============================================================

/**
 * 安全规则列表
 */
export const GUARDRAIL_RULES = [
  // 禁止表达
  { pattern: /你(患|得|有)(了|上)?帕金森/gi, message: '禁止做出诊断结论' },
  { pattern: /你的病情(恶化|加重|加重了)/gi, message: '禁止用"恶化""加重"等刺激性描述' },
  { pattern: /建议(增加|减少|调整)(药量|剂量|用药)/gi, message: '禁止建议药物剂量调整' },
  { pattern: /(加|减|停)(药|吃)/gi, message: '禁止提及药物调整' },
  { pattern: /推荐(你|您)(使用|服用)/gi, message: '禁止推荐药物' },
  { pattern: /这个(病|疾病)(是|可能)/gi, message: '禁止对疾病定性' },
  { pattern: /不用(去|看)(医院|医生)/gi, message: '禁止替代医疗建议' },
  { pattern: /(预测|预计|一定)(会|能)/gi, message: '禁止绝对化预测' },
];

/**
 * 后处理护栏：检查并修正 LLM 输出
 * 返回 { passed: true } 或 { passed: false, violations: string[] }
 */
export function checkGuardrails(text: string): {
  passed: boolean;
  violations: string[];
} {
  const violations: string[] = [];

  for (const rule of GUARDRAIL_RULES) {
    if (rule.pattern.test(text)) {
      violations.push(rule.message);
    }
  }

  return {
    passed: violations.length === 0,
    violations,
  };
}

/**
 * 裁剪护栏：如果输出中有违规内容，用安全版本替换
 */
export function sanitizeOutput(text: string): string {
  let sanitized = text;

  // 替换违禁模式
  sanitized = sanitized.replace(
    /你(患|得|有)(了|上)?帕金森/gi,
    '检测到帕金森综合征相关的运动模式',
  );
  sanitized = sanitized.replace(
    /(恶化|加重|加重了)/gi,
    '有变化',
  );
  sanitized = sanitized.replace(
    /建议(增加|减少|调整)(药量|剂量|用药)/gi,
    '建议与医生讨论用药方案',
  );

  // 确保以"建议咨询医生"结尾（如果内容涉及异常）
  // 注意：这条由 prompt 保证，这里不做强制追加以免啰嗦

  return sanitized;
}

/**
 * 护栏摘要，用于追加到 system prompt 尾部
 */
export function guardrailsSystemPrompt(): string {
  return `
## 安全规则（必须严格遵守）
1. 不做诊断。所有分析以"检测到"、"观察到"开头，不以"你患有"开头。
2. 不提供药物剂量建议。用药相关只描述时间关联关系，不做"增加/减少药量"的建议。
3. 任何异常结果都以"建议咨询医生"结尾。
4. 不使用"恶化""加重"等刺激性词汇，用"有变化""出现波动"替代。
5. 不使用绝对化语言（"一定""必然"），使用"可能""建议考虑"。
6. 保持温和积极的语气，不制造焦虑。
7. 不预测未来病情发展。`;
}
