// Server-side PostHog adapter. Telemetry is best-effort and never blocks user requests.
const host = (process.env.POSTHOG_HOST || 'https://us.i.posthog.com').replace(/\/$/, '');
const apiKey = process.env.POSTHOG_API_KEY;

export function telemetryEnabled() {
  return Boolean(apiKey);
}

export function captureEvent(event, properties = {}, distinctId = 'anonymous') {
  if (!apiKey || !event) return Promise.resolve(false);
  const payload = {
    api_key: apiKey,
    event,
    distinct_id: String(distinctId || 'anonymous'),
    properties: {
      ...properties,
      source: 'xactions-api',
      environment: process.env.NODE_ENV || 'development',
    },
    timestamp: new Date().toISOString(),
  };

  return fetch(`${host}/capture/`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(2500),
  }).then((response) => response.ok).catch((error) => {
    if (process.env.DEBUG) console.warn('PostHog capture failed:', error.message);
    return false;
  });
}

export function captureRequest(req, event, properties = {}) {
  return captureEvent(event, {
    method: req.method,
    path: req.route?.path || req.path,
    requestId: req.id,
    ...properties,
  }, req.user?.clerkId || req.user?.id || 'anonymous');
}
