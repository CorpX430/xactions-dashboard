(() => {
  'use strict';
  const mount = document.querySelector('.main-content') || document.querySelector('main');
  if (!mount) return;
  const panel = document.createElement('section');
  panel.className = 'integration-status-panel';
  panel.style.cssText = 'margin:16px 0;padding:16px;border:1px solid var(--border);border-radius:14px;background:var(--bg-secondary, #16181c);';
  panel.innerHTML = '<strong>Integration health</strong><div role="status" style="margin-top:10px;color:var(--text-secondary)">Checking connected services…</div>';
  const heading = mount.querySelector('h1, h2');
  if (heading?.parentElement) heading.parentElement.after(panel); else mount.prepend(panel);

  const escapeHtml = (value) => { const div = document.createElement('div'); div.textContent = String(value ?? ''); return div.innerHTML; };
  async function load() {
    const status = panel.querySelector('[role="status"]');
    try {
      const token = localStorage.getItem('authToken');
      const response = await fetch('/api/enhanced/status', { headers: token ? { Authorization: `Bearer ${token}` } : {} });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || response.statusText);
      const entries = Object.entries(data.integrations || {});
      status.innerHTML = entries.map(([name, configured]) => `<span style="display:inline-flex;gap:6px;margin:8px 12px 0 0;color:${configured ? 'var(--success, #00ba7c)' : 'var(--text-secondary)'}"><span aria-hidden="true">${configured ? '●' : '○'}</span>${escapeHtml(name)}: ${configured ? 'ready' : 'not configured'}</span>`).join('') || 'No external integrations configured.';
    } catch (error) {
      status.innerHTML = `<span style="color:var(--warning, #ffad1f)">Unable to check integration status: ${escapeHtml(error.message)}</span>`;
    }
  }
  load();
})();
