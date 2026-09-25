#!/bin/sh

# Run database migrations only if DATABASE_URL is available. Never block the
# web process indefinitely: Render must be able to observe the HTTP port even
# when a remote database is temporarily unavailable or a pooler is restarting.
if [ -n "$DATABASE_URL" ]; then
  echo "🔄 Running database migrations..."
  # Fresh DB: migrate deploy runs 0_init SQL and creates all tables.
  # Existing DB (created with db push, no migration history): deploy fails on
  # "relation already exists", so we mark the baseline as applied and redeploy.
  timeout 90s npx prisma migrate deploy || {
    echo "⚠️  Tables exist without migration history - marking baseline as applied..."
    timeout 30s npx prisma migrate resolve --applied "0_init" && timeout 90s npx prisma migrate deploy
  } || echo "⚠️  Migration warning (non-fatal), continuing..."
else
  echo "⚠️ DATABASE_URL not set, skipping migrations"
fi

exec node api/server.js
