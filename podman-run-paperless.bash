#!/usr/bin/env bash
set -euo pipefail

# Podman run script for Paperless-ngx (with Redis)

NETWORK="paperless-net"
DATA_DIR="${pwd}/paperless/data"
MEDIA_DIR="${pwd}/paperless/media"
EXPORT_DIR="${pwd}/paperless/export"
CONSUME_DIR="${pwd}/paperless/consume"

mkdir -p "${DATA_DIR}" "${MEDIA_DIR}" "${EXPORT_DIR}" "${CONSUME_DIR}"

# Create network if it doesn't exist
podman network exists "${NETWORK}" || podman network create "${NETWORK}"

# Redis (broker)
podman run -d \
  --name paperless-redis \
  --network "${NETWORK}" \
  --restart unless-stopped \
  docker.io/library/redis:7

# Paperless-ngx
podman run -d \
  --name paperless-ngx \
  --network "${NETWORK}" \
  --restart unless-stopped \
  -p 8000:8000 \
  -v "${DATA_DIR}:/usr/src/paperless/data:Z" \
  -v "${MEDIA_DIR}:/usr/src/paperless/media:Z" \
  -v "${EXPORT_DIR}:/usr/src/paperless/export:Z" \
  -v "${CONSUME_DIR}:/usr/src/paperless/consume:Z" \
  -e PAPERLESS_REDIS="redis://paperless-redis:6379" \
  -e PAPERLESS_URL="http://localhost:8000" \
  -e PAPERLESS_TIME_ZONE="UTC" \
  -e PAPERLESS_OCR_LANGUAGE="eng" \
  ghcr.io/paperless-ngx/paperless-ngx:latest

echo "Paperless-ngx is starting at http://localhost:8000"
echo "Create a superuser with:"
echo "  podman exec -it paperless-ngx python manage.py createsuperuser"
