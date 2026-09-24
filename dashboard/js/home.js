(function () {
  'use strict';
  function mount() {
    const main = document.querySelector('.main-content');
    if (!main || !window.CONFIG || document.querySelector('.shell-status-card')) return;

    const status = document.createElement('section');
    status.className = 'panel shell-status-card';
    status.setAttribute('aria-labelledby', 'system-status-title');
    status.innerHTML = `
      <div class="panel__header"><div><h2 id="system-status-title">System status</h2><p style="color:var(--text-secondary);font-size:.78rem;margin-top:3px">Live service checks for your workspace</p></div><span class="shell-status-dot" id="system-status-dot" aria-label="Checking"></span></div>
      <div class="panel__body" id="system-status-body"><div class="ui-state" style="min-height:100px"><div class="skeleton-block" style="width:70%;height:14px"></div><div class="skeleton-block" style="width:45%;height:12px"></div></div></div>`;
    const anchor = main.querySelector('.operations-section') || main.firstElementChild;
    main.insertBefore(status, anchor || null);

    const body = status.querySelector('#system-status-body');
    const dot = status.querySelector('#system-status-dot');
    const check = async () => {
      try {
        const started = performance.now();
        const response = await fetch(`${CONFIG.API_BASE}/health`, { headers: { Accept: 'application/json' } });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`);
        const realtime = Boolean(window.io || window.socket);
        dot.classList.remove('offline');
        dot.setAttribute('aria-label', 'Operational');
        body.innerHTML = `<div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px"><div><strong style="color:var(--success)">Operational</strong><div style="color:var(--text-secondary);font-size:.78rem;margin-top:4px">API gateway</div></div><div><strong>${Math.round(performance.now() - started)}ms</strong><div style="color:var(--text-secondary);font-size:.78rem;margin-top:4px">Response time</div></div><div><strong style="color:${realtime ? 'var(--success)' : 'var(--warning)'}">${realtime ? 'Connected' : 'Standby'}</strong><div style="color:var(--text-secondary);font-size:.78rem;margin-top:4px">Realtime transport</div></div></div>`;
      } catch (error) {
        dot.classList.add('offline');
        dot.setAttribute('aria-label', 'Degraded');
        body.innerHTML = `<div class="ui-state ui-state--error" style="min-height:100px;padding:6px"><div class="ui-state__icon">!</div><h3>Some services are unavailable</h3><p>${error.message}. Your local tools remain available.</p><button class="btn btn--secondary" id="retry-status">Retry</button></div>`;
        body.querySelector('#retry-status').addEventListener('click', check);
      }
    };
    check();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount, { once: true });
  else mount();
})();
