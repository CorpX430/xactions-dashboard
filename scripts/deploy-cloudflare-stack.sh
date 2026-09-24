#!/usr/bin/env bash
set -euo pipefail

: "${CLOUDFLARE_PAGES_PROJECT:=xactions}"
: "${CLOUDFLARE_PAGES_BRANCH:=main}"

command -v npx >/dev/null || { echo 'npx is required' >&2; exit 1; }

echo 'Building static Pages output…'
node scripts/build-cloudflare.mjs

echo 'Deploying Cloudflare Pages…'
npx wrangler pages deploy pages-out --project-name "$CLOUDFLARE_PAGES_PROJECT" --branch "$CLOUDFLARE_PAGES_BRANCH" --commit-dirty=true

echo 'Deploying Cloudflare Worker gateway…'
(cd cloudflare && npx wrangler deploy --env production)

echo 'Cloudflare Pages + Worker deployment complete.'
