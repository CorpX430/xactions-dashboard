export interface Env {
  API_ORIGIN: string;
  ALLOWED_ORIGIN?: string;
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
}

const json = (body: unknown, status = 200, headers: HeadersInit = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...headers },
  });

function corsHeaders(request: Request, env: Env): HeadersInit {
  const origin = request.headers.get("Origin");
  const allowed = env.ALLOWED_ORIGIN ? (origin === env.ALLOWED_ORIGIN ? origin : "null") : (origin || "*");
  return {
    "access-control-allow-origin": allowed,
    "access-control-allow-credentials": "true",
    "access-control-allow-headers": "authorization, content-type, x-request-id",
    "access-control-allow-methods": "GET,POST,PUT,PATCH,DELETE,OPTIONS",
    vary: "Origin",
  };
}

function securityHeaders(): HeadersInit {
  return {
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": "strict-origin-when-cross-origin",
    "permissions-policy": "camera=(), microphone=(), geolocation=()",
    "strict-transport-security": "max-age=31536000; includeSubDomains",
  };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const headers = { ...corsHeaders(request, env), ...securityHeaders() };
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });

    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return json({ status: "ok", service: "xactions-edge-gateway" }, 200, headers);
    }

    if (!url.pathname.startsWith("/api/")) {
      return json({ error: "not_found" }, 404, headers);
    }

    if (!env.API_ORIGIN) return json({ error: "api_origin_not_configured" }, 503, headers);
    const upstream = new URL(url.pathname + url.search, env.API_ORIGIN);
    const proxyHeaders = new Headers(request.headers);
    proxyHeaders.set("x-forwarded-host", url.host);
    proxyHeaders.set("x-forwarded-proto", url.protocol.replace(":", ""));

    let response: Response;
    try {
      response = await fetch(new Request(upstream, {
        method: request.method,
        headers: proxyHeaders,
        body: ["GET", "HEAD"].includes(request.method) ? undefined : request.body,
        redirect: "manual",
      }));
    } catch {
      return json({ error: "upstream_unavailable" }, 502, headers);
    }

    const outputHeaders = new Headers(response.headers);
    Object.entries(headers).forEach(([key, value]) => outputHeaders.set(key, String(value)));
    return new Response(response.body, { status: response.status, headers: outputHeaders });
  },
};
