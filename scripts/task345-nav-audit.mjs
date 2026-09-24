import fs from 'node:fs';
const source = fs.readFileSync('dashboard/js/sidebar.js', 'utf8');
const hrefs = [...source.matchAll(/href: '([^']+)'/g)].map((match) => match[1]).filter((href) => href.startsWith('/'));
const pages = new Set(fs.readdirSync('dashboard').filter((file) => file.endsWith('.html')).map((file) => `/${file.replace(/\.html$/, '')}`));
const serverRoutes = new Set(['/','/dashboard','/scripts','/docs','/features','/blog','/use-cases','/compare','/pricing','/faq','/changelog','/contact','/status','/about','/login','/run','/tutorials','/mcp','/ai','/ai-api','/privacy','/terms','/admin','/analytics','/automations','/agent','/monitor','/unfollowers','/workflows','/thread','/video','/analytics-dashboard','/calendar','/thread-composer','/team','/price-correlation','/graph','/a2a','/integrations','/ask']);
const missing = hrefs.filter((href) => !pages.has(href) && !serverRoutes.has(href));
console.log(JSON.stringify({ total: hrefs.length, missing }, null, 2));
if (missing.length) process.exit(1);
