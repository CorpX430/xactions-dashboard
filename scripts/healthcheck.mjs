const base = (process.argv[2] || process.env.HEALTHCHECK_URL || 'http://127.0.0.1:3001').replace(/\/$/, '');
const paths = ['/api/health', '/health'];
let passed = 0;
for (const path of paths) {
  try {
    const response = await fetch(`${base}${path}`, { signal: AbortSignal.timeout(8000) });
    const body = await response.text();
    if (response.ok) { console.log(`PASS ${path} ${response.status} ${body.slice(0, 160)}`); passed += 1; }
    else console.log(`WARN ${path} ${response.status} ${body.slice(0, 160)}`);
  } catch (error) { console.log(`WARN ${path} ${error.message}`); }
}
if (!passed) { console.error('No health endpoint responded successfully.'); process.exit(1); }
