const DEFAULT_TIMEOUT_MS = 30_000;

function envNumber(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

async function fetchJson(url, options = {}, timeoutMs = DEFAULT_TIMEOUT_MS) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    const text = await response.text();
    let body;
    try { body = text ? JSON.parse(text) : {}; } catch { body = { raw: text }; }
    if (!response.ok) {
      const error = new Error(body?.error?.message || body?.error || body?.message || `External service returned ${response.status}`);
      error.status = response.status;
      throw error;
    }
    return body;
  } finally {
    clearTimeout(timer);
  }
}

function requireKey(name) {
  const key = process.env[name];
  if (!key) {
    const error = new Error(`${name} is not configured`);
    error.code = 'INTEGRATION_NOT_CONFIGURED';
    error.status = 503;
    throw error;
  }
  return key;
}

export async function firecrawlScrape({ url, formats = ['markdown'], onlyMainContent = true }) {
  if (!url) throw Object.assign(new Error('url is required'), { status: 400 });
  const apiKey = requireKey('FIRECRAWL_API_KEY');
  return fetchJson(`${process.env.FIRECRAWL_BASE_URL || 'https://api.firecrawl.dev'}/v2/scrape`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ url, formats, onlyMainContent }),
  }, envNumber('EXTERNAL_REQUEST_TIMEOUT_MS', DEFAULT_TIMEOUT_MS));
}

export async function anchorFetch({ url, prompt }) {
  if (!url) throw Object.assign(new Error('url is required'), { status: 400 });
  const apiKey = requireKey('ANCHOR_API_KEY');
  const response = await fetchJson(`${process.env.ANCHOR_BASE_URL || 'https://api.anchorbrowser.io/v1'}/tools/fetch/webpage`, {
    method: 'POST',
    headers: { 'anchor-api-key': apiKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ url, ...(prompt ? { prompt } : {}) }),
  }, envNumber('EXTERNAL_REQUEST_TIMEOUT_MS', DEFAULT_TIMEOUT_MS));
  return response?.data ?? response;
}

export async function openRouterChat({ messages, model, temperature = 0.7, maxTokens = 800, responseFormat }) {
  if (!Array.isArray(messages) || messages.length === 0) throw Object.assign(new Error('messages are required'), { status: 400 });
  const apiKey = requireKey('OPENROUTER_API_KEY');
  const body = {
    model: model || process.env.OPENROUTER_MODEL || 'openrouter/auto',
    messages,
    temperature,
    max_tokens: maxTokens,
    ...(responseFormat ? { response_format: responseFormat } : {}),
  };
  const response = await fetchJson(`${process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1'}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': process.env.FRONTEND_URL || 'https://xactions.app',
      'X-Title': 'XActions Dashboard',
    },
    body: JSON.stringify(body),
  }, envNumber('EXTERNAL_REQUEST_TIMEOUT_MS', DEFAULT_TIMEOUT_MS));
  return {
    id: response.id,
    model: response.model,
    content: response.choices?.[0]?.message?.content || '',
    usage: response.usage || null,
    raw: process.env.NODE_ENV === 'development' ? response : undefined,
  };
}

export function integrationStatus() {
  return {
    firecrawl: Boolean(process.env.FIRECRAWL_API_KEY),
    anchor: Boolean(process.env.ANCHOR_API_KEY),
    openrouter: Boolean(process.env.OPENROUTER_API_KEY),
  };
}
