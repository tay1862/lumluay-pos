# VPS Deployment Guide

This guide deploys LUMLUAY POS to a fresh Ubuntu 22.04 VPS with Docker Compose, Nginx, PostgreSQL, Redis, and Let's Encrypt.

## 1. Requirements

- Ubuntu 22.04 VPS
- Domain pointed to the VPS public IP
- Ports `80` and `443` open
- SSH access with sudo

## 2. Clone the Repository

```bash
git clone https://github.com/tay1862/lumluay-pos.git /opt/lumluay
cd /opt/lumluay
```

## 3. Run Initial VPS Setup

```bash
sudo bash scripts/setup-vps.sh
```

What this script does:

- installs Docker and Compose
- configures UFW
- prepares `/opt/lumluay`
- creates `lumluay-api/.env`
- starts the production stack
- runs migrations and production seed
- prepares SSL renewal cron

## 4. Configure Production Environment

Edit the API env file:

```bash
nano /opt/lumluay/lumluay-api/.env
```

Set these values correctly:

```env
NODE_ENV=production
DATABASE_URL=postgresql://lumluay:STRONG_DB_PASSWORD@postgres:5432/lumluay_db
POSTGRES_PASSWORD=STRONG_DB_PASSWORD
REDIS_PASSWORD=STRONG_REDIS_PASSWORD
JWT_SECRET=<64+ char secret>
JWT_REFRESH_SECRET=<different 64+ char secret>
SUPER_ADMIN_USERNAME=superadmin
SUPER_ADMIN_PASSWORD=<strong password>
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com
DOMAIN=your-domain.com
CERTBOT_EMAIL=you@example.com
```

Generate secrets with:

```bash
openssl rand -base64 48
```

## 5. Build Flutter Web for Nginx

The production Nginx container serves static files from `lumluay-app/build/web`, so build the web app before deployment or after frontend changes:

```bash
cd /opt/lumluay/lumluay-app
flutter pub get
flutter build web
```

Then go back to the repo root:

```bash
cd /opt/lumluay
```

## 6. Deploy the Production Stack

```bash
bash scripts/deploy.sh
```

This runs:

- `docker compose -f docker-compose.prod.yml up -d --build`
- `npm run db:migrate`
- `npm run db:seed:prod`

## 7. Issue SSL Certificates

Once DNS resolves correctly:

```bash
DOMAIN=your-domain.com CERTBOT_EMAIL=you@example.com \
docker compose -f docker-compose.prod.yml --profile certbot run --rm certbot
```

After the certificate is issued:

1. edit `nginx/conf.d/ssl.conf` and replace every `YOUR_DOMAIN` with the real domain
2. reload Nginx:

```bash
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

## 8. Health Checks

Useful commands:

```bash
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f nginx
curl http://localhost/healthz
curl http://localhost/api/health
```

Expected routes through Nginx:

- `/api/` forwards to `api:3000/v1/`
- `/socket.io/` forwards WebSocket traffic
- `/uploads/` serves uploaded assets
- `/` serves Flutter web from `lumluay-app/build/web`

## 9. Updates

For future deploys:

```bash
cd /opt/lumluay
git pull
cd lumluay-app && flutter build web && cd ..
bash scripts/deploy.sh
```

## 10. Notes

- Production JWT secrets are mandatory; the API now fails fast if they are missing in production.
- The WebSocket gateway requires JWT authentication.
- Database money fields were aligned to higher precision for production use.
- `scripts/setup-vps.sh` assumes this repository by default.