// ============================================================
// DeepSeek API 客户端
// 使用 fetch() 调用 DeepSeek V4-Pro API
// ============================================================

// 从环境变量读取，通过 Supabase 的 secrets 或项目配置注入
const DEEPSEEK_API_KEY = () => Deno.env.get('DEEPSEEK_API_KEY') || '';
const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_MODEL = 'deepseek-v4-pro';  // 或 deepseek-chat

export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface ChatCompletionRequest {
  messages: ChatMessage[];
  temperature?: number;
  max_tokens?: number;
  response_format?: { type: 'json_object' };
}

export interface ChatCompletionResponse {
  id: string;
  choices: {
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }[];
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

/**
 * 调用 DeepSeek V4-Pro API
 */
export async function callDeepSeek(
  request: ChatCompletionRequest,
): Promise<ChatCompletionResponse> {
  const apiKey = DEEPSEEK_API_KEY();
  if (!apiKey) {
    throw new Error('DEEPSEEK_API_KEY 未配置。请在 Supabase 项目设置中配置。');
  }

  const response = await fetch(DEEPSEEK_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: DEEPSEEK_MODEL,
      ...request,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`DeepSeek API 错误 (${response.status}): ${errorBody}`);
  }

  return await response.json();
}

/**
 * 安全地解析 DeepSeek 返回的 JSON
 */
export function parseJsonResponse<T>(rawContent: string): T | null {
  try {
    // 尝试直接解析
    return JSON.parse(rawContent) as T;
  } catch {
    // 尝试从 markdown code block 中提取
    const jsonMatch = rawContent.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      try {
        return JSON.parse(jsonMatch[1]) as T;
      } catch {
        return null;
      }
    }
    return null;
  }
}
