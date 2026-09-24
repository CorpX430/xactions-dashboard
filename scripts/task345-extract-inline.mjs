import fs from 'node:fs';
import path from 'node:path';

for (const name of ['graph', 'workflows', 'analytics-dashboard']) {
  const html = fs.readFileSync(path.join('dashboard', `${name}.html`), 'utf8');
  const scripts = [...html.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/gi)]
    .filter((match) => !/type=["']application\/ld\+json["']/i.test(match[1]) && !/src=/i.test(match[1]))
    .map((match) => match[2].trim())
    .filter(Boolean);
  fs.writeFileSync(`/tmp/xactions-${name}-inline.mjs`, scripts.join('\n\n'));
  console.log(`${name}: extracted ${scripts.length} inline scripts`);
}
