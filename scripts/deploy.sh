#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="lumluay-api/.env"

echo "[deploy] Pull latest images"
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml pull || true

echo "[deploy] Build and start services"
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml up -d --build

echo "[deploy] Run migrations"
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml exec -T api npm run db:migrate

echo "[deploy] Seed production defaults"
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml exec -T api npm run db:seed:prod

echo "[deploy] Deployment finished"
