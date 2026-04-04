#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# scripts/setup-vps.sh — Initial Ubuntu 22.04 LTS VPS setup for LUMLUAY POS
#
# Usage (run as root or with sudo on a fresh VPS):
#   curl -fsSL https://raw.githubusercontent.com/tay1862/lumluay-pos/main/scripts/setup-vps.sh | bash
#   — or —
#   git clone https://github.com/tay1862/lumluay-pos.git /opt/lumluay
#   cd /opt/lumluay && sudo bash scripts/setup-vps.sh
#
# What this does:
#   1. Update system packages
#   2. Install Docker + Docker Compose v2
#   3. Install ufw firewall rules (80, 443, SSH)
#   4. Create deploy user with Docker group membership
#   5. Clone/configure app directory
#   6. Prompt for .env values
#   7. Build & start production stack
#   8. Issue Let's Encrypt certificate
#   9. Set up auto-renew cron
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colours ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[setup]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn] ${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Guards ─────────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || error "Run this script as root or with sudo"
[[ "$(lsb_release -is 2>/dev/null)" == "Ubuntu" ]] || warn "This script targets Ubuntu; proceeding anyway"

APP_DIR="${APP_DIR:-/opt/lumluay}"
DEPLOY_USER="${DEPLOY_USER:-lumluay}"
GIT_REPO="${GIT_REPO:-https://github.com/tay1862/lumluay-pos.git}"

# ══════════════════ 1. System packages ════════════════════════════════════════
info "Updating system packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
apt-get install -y -qq \
  curl wget git openssl ufw \
  ca-certificates gnupg lsb-release

# ══════════════════ 2. Docker ═════════════════════════════════════════════════
if ! command -v docker &>/dev/null; then
  info "Installing Docker CE..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable --now docker
  info "Docker $(docker --version) installed"
else
  info "Docker already installed: $(docker --version)"
fi

# ══════════════════ 3. Firewall ════════════════════════════════════════════════
info "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
info "UFW status:"; ufw status

# ══════════════════ 4. Deploy user ════════════════════════════════════════════
if ! id "$DEPLOY_USER" &>/dev/null; then
  info "Creating deploy user '$DEPLOY_USER'..."
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi
usermod -aG docker "$DEPLOY_USER"
info "User '$DEPLOY_USER' is in docker group"

# ══════════════════ 5. App directory ═══════════════════════════════════════════
info "Setting up app directory at $APP_DIR..."
mkdir -p "$APP_DIR"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"

# Clone or update repository
if [[ -d "$APP_DIR/.git" ]]; then
  info "Pulling latest from $GIT_REPO..."
  git -C "$APP_DIR" pull
else
  info "Cloning $GIT_REPO..."
  git clone "$GIT_REPO" "$APP_DIR"
  chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"
fi

# ══════════════════ 6. Environment file ════════════════════════════════════════
ENV_FILE="$APP_DIR/lumluay-api/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  info "Creating .env from .env.production.example..."
  cp "$APP_DIR/lumluay-api/.env.production.example" "$ENV_FILE"
  warn "────────────────────────────────────────────────────────────"
  warn " IMPORTANT: Edit $ENV_FILE and fill in all ← REQUIRED values"
  warn " Then re-run:  cd $APP_DIR && bash scripts/deploy.sh"
  warn "────────────────────────────────────────────────────────────"
  # Auto-generate secrets if placeholders are still present
  if grep -q 'REPLACE_WITH_64_CHAR_RANDOM_STRING' "$ENV_FILE"; then
    JWT_SECRET="$(openssl rand -base64 48)"
    JWT_REFRESH_SECRET="$(openssl rand -base64 48)"
    sed -i "s|REPLACE_WITH_64_CHAR_RANDOM_STRING|${JWT_SECRET}|g"           "$ENV_FILE"
    sed -i "s|REPLACE_WITH_DIFFERENT_64_CHAR_RANDOM_STRING|${JWT_REFRESH_SECRET}|g" "$ENV_FILE"
    info "Auto-generated JWT secrets in $ENV_FILE"
  fi
else
  info ".env already exists — skipping"
fi

# ══════════════════ 7. Build & start ══════════════════════════════════════════
info "Building and starting production stack..."
cd "$APP_DIR"
docker compose -f docker-compose.prod.yml pull --quiet
docker compose -f docker-compose.prod.yml up -d --build
info "Running DB migrations..."
docker compose -f docker-compose.prod.yml exec -T api npm run db:migrate || warn "Migration step failed — check logs"
info "Seeding production defaults..."
docker compose -f docker-compose.prod.yml exec -T api npm run db:seed:prod || warn "Seed step failed — might already be seeded"

# ══════════════════ 8. Let's Encrypt certificate ═══════════════════════════════
DOMAIN="${DOMAIN:-}"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-}"

if [[ -n "$DOMAIN" && -n "$CERTBOT_EMAIL" ]]; then
  info "Issuing Let's Encrypt certificate for $DOMAIN..."
  DOMAIN="$DOMAIN" CERTBOT_EMAIL="$CERTBOT_EMAIL" \
    docker compose -f docker-compose.prod.yml \
      --profile certbot run --rm certbot || warn "Certificate issuance failed — check logs"
  info "Reloading nginx..."
  docker compose -f docker-compose.prod.yml exec nginx nginx -s reload || true
else
  warn "DOMAIN or CERTBOT_EMAIL not set — skipping certificate issuance."
  warn "Set them and run:  DOMAIN=your.domain CERTBOT_EMAIL=you@mail.com \\"
  warn "  docker compose -f docker-compose.prod.yml --profile certbot run --rm certbot"
fi

# ══════════════════ 9. Auto-renew cron ════════════════════════════════════════
RENEW_SCRIPT="$APP_DIR/scripts/renew-certs.sh"
cat > "$RENEW_SCRIPT" <<'RENEW'
#!/usr/bin/env bash
set -euo pipefail
cd /opt/lumluay
DOMAIN="${DOMAIN:-}" CERTBOT_EMAIL="${CERTBOT_EMAIL:-}" \
  docker compose -f docker-compose.prod.yml --profile certbot run --rm certbot renew --quiet
docker compose -f docker-compose.prod.yml exec nginx nginx -s reload
RENEW
chmod +x "$RENEW_SCRIPT"

CRON_LINE="0 3 * * * $RENEW_SCRIPT >> /var/log/lumluay-cert-renew.log 2>&1"
(crontab -l 2>/dev/null | grep -qF "$RENEW_SCRIPT") \
  || (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
info "Certificate auto-renew cron registered (daily at 03:00)"

# ══════════════════ Done ══════════════════════════════════════════════════════
info "════════════════════════════════════════════════════════════"
info " LUMLUAY POS VPS setup complete!"
info ""
info " Stack status:"
docker compose -f "$APP_DIR/docker-compose.prod.yml" ps
info ""
info " Next steps:"
info "  1. Verify .env at $ENV_FILE has correct values"
info "  2. Point your DNS A record for \$DOMAIN → $(curl -s ifconfig.me 2>/dev/null || echo '<VPS IP>')"
info "  3. Issue SSL cert:  DOMAIN=your.domain CERTBOT_EMAIL=you@mail.com \\"  
info "       docker compose -f docker-compose.prod.yml --profile certbot run --rm certbot"
info "  4. Reload nginx:    docker compose -f docker-compose.prod.yml exec nginx nginx -s reload"
info "  5. Swap nginx config to ssl.conf after cert is issued"
info "════════════════════════════════════════════════════════════"
