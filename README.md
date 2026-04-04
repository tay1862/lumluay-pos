# LUMLUAY POS

LUMLUAY POS is a full-stack restaurant point-of-sale system with a NestJS API, a Flutter cashier app, offline-first sync, WebSocket updates, and Docker-based production deployment for VPS hosting.

## Repository Layout

- `lumluay-api/` NestJS API, Drizzle ORM schema, migrations, seeds, and integration tests
- `lumluay-app/` Flutter POS app for Android, iOS, and web
- `docs/design/` product, architecture, database, and UI design documents
- `monitoring/` Prometheus configuration
- `nginx/` reverse proxy and TLS configuration
- `scripts/` deployment and VPS bootstrap scripts

## Tech Stack

- Backend: NestJS, Fastify, Drizzle ORM, PostgreSQL 16, Redis 7, Socket.IO, BullMQ
- Frontend: Flutter, Riverpod, Drift, Dio, SQLCipher
- Infra: Docker Compose, Nginx, Let's Encrypt, Prometheus

## Local Development

### API

```bash
cd lumluay-api
npm install
npm run start:dev
```

### Flutter App

```bash
cd lumluay-app
flutter pub get
flutter run
```

### Full Stack with Docker

```bash
cp lumluay-api/.env.example lumluay-api/.env
docker compose up -d
```

Services:

- API: `http://localhost:3000/v1`
- Postgres: `localhost:5432`
- PgBouncer: `localhost:5433`
- Redis: `localhost:6379`

## Production Deployment on VPS

The repository includes a complete Docker-based VPS deployment flow.

Quick path:

```bash
git clone https://github.com/tay1862/lumluay-pos.git /opt/lumluay
cd /opt/lumluay
sudo bash scripts/setup-vps.sh
```

The production stack uses:

- `docker-compose.prod.yml`
- `scripts/setup-vps.sh`
- `scripts/deploy.sh`
- `nginx/conf.d/default.conf`
- `nginx/conf.d/ssl.conf`

Detailed instructions are in [docs/VPS_DEPLOYMENT.md](docs/VPS_DEPLOYMENT.md).

## Required Production Configuration

Copy and fill the API environment file:

```bash
cp lumluay-api/.env.production.example lumluay-api/.env
```

Minimum required values:

- `DATABASE_URL`
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `SUPER_ADMIN_USERNAME`
- `SUPER_ADMIN_PASSWORD`
- `DOMAIN`
- `CERTBOT_EMAIL`

## Verification

Validated in this repository state:

- Flutter app analyzes cleanly in app code
- API TypeScript compiles cleanly with `npx tsc --noEmit`
- WebSocket auth, JWT secret enforcement, backup command hardening, and schema precision fixes are applied

## Release

Initial repository import and first release tag are tracked from this repository state.