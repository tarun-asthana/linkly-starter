#!/usr/bin/env bash
# Build and start the Linkly stack on three segmented networks.
# Safe to run again: existing networks, volumes and containers are left as they are.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
API_IMAGE="${API_IMAGE:-linkly-api:$TAG}"
WORKER_IMAGE="${WORKER_IMAGE:-linkly-worker:$TAG}"
PROXY_IMAGE="nginxinc/nginx-unprivileged:1.27-alpine"
DB_IMAGE="postgres:16-alpine"
CACHE_IMAGE="redis:7.4-alpine"

# Hardening flags shared by every container.
HARDEN=(
  --cap-drop ALL
  --security-opt no-new-privileges
  --read-only --tmpfs /tmp
  --memory 256m --cpus 0.5
  --log-opt max-size=10m --log-opt max-file=3
  --restart unless-stopped
)
SECRET=(-v "$PWD/secrets/db_password:/run/secrets/db_password:ro")

create_network() { # name subnet [extra flags]
  if ! docker network inspect "$1" >/dev/null 2>&1; then
    docker network create --subnet "$2" "${@:3}" "$1" >/dev/null
    echo "network $1 created"
  fi
}

run_once() { # name, then docker run arguments
  local name=$1; shift
  if docker container inspect "$name" >/dev/null 2>&1; then
    echo "$name already exists"
  else
    docker run -d --name "$name" "$@" >/dev/null
    echo "$name started"
  fi
}

connect_once() { # network container
  if ! docker inspect -f '{{json .NetworkSettings.Networks}}' "$2" | grep -q "\"$1\""; then
    docker network connect "$1" "$2"
  fi
}

wait_healthy() { # container
  local status
  for _ in $(seq 1 60); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$1")"
    if [ "$status" = "healthy" ]; then
      echo "$1 healthy"
      return 0
    fi
    sleep 2
  done
  echo "$1 did not become healthy; last logs:" >&2
  docker logs --tail 20 "$1" >&2
  return 1
}

# 1. Secret and TLS certificate. Both are gitignored and generated on first run.
mkdir -p secrets
[ -f secrets/db_password ] || openssl rand -hex 16 > secrets/db_password
chmod 644 secrets/db_password
[ -f proxy/certs/tls.crt ] || ./proxy/gen-cert.sh >/dev/null

# 2. Images.
docker build -q -t "$API_IMAGE" api >/dev/null
docker build -q -t "$WORKER_IMAGE" worker >/dev/null

# 3. Networks and volumes.
create_network dmz      172.30.1.0/24
create_network internal 172.30.2.0/24 --internal
create_network admin    172.30.3.0/24 --internal
for v in pgdata redisdata reports; do docker volume create "$v" >/dev/null; done

# 4. Data tier first, then the app, then the proxy.
run_once db --network internal "${HARDEN[@]}" "${SECRET[@]}" \
  --user postgres --tmpfs /var/run/postgresql:mode=1777 \
  -e POSTGRES_USER=linkly -e POSTGRES_DB=linkly \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/db_password \
  -v pgdata:/var/lib/postgresql/data \
  --health-cmd 'pg_isready -U linkly -d linkly' --health-interval 5s --health-retries 12 \
  "$DB_IMAGE"
connect_once admin db

run_once cache --network internal "${HARDEN[@]}" \
  --user redis -v redisdata:/data \
  --health-cmd 'redis-cli ping' --health-interval 5s --health-retries 12 \
  "$CACHE_IMAGE" redis-server --appendonly yes

wait_healthy db
wait_healthy cache

run_once api --network internal "${HARDEN[@]}" "${SECRET[@]}" \
  -e DB_HOST=db -e REDIS_HOST=cache -e DB_PASSWORD_FILE=/run/secrets/db_password \
  "$API_IMAGE"
connect_once dmz api

run_once worker --network internal "${HARDEN[@]}" "${SECRET[@]}" --init \
  -e DB_HOST=db -e REDIS_HOST=cache -e DB_PASSWORD_FILE=/run/secrets/db_password \
  -e WEBHOOK_URL= -v reports:/data/reports \
  "$WORKER_IMAGE"

wait_healthy api
wait_healthy worker

run_once proxy --network dmz "${HARDEN[@]}" \
  -p 80:8080 -p 443:8443 \
  -v "$PWD/proxy/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$PWD/proxy/certs:/etc/nginx/certs:ro" \
  --health-cmd 'wget -q -O /dev/null http://127.0.0.1:8080/healthz' --health-interval 5s --health-retries 12 \
  "$PROXY_IMAGE"
wait_healthy proxy

echo "Stack is up: https://localhost"
