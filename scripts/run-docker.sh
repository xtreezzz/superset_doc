#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "[error] docker is not installed or not available in PATH"
  exit 127
fi

if ! docker info >/dev/null 2>&1; then
  echo "[error] docker daemon is not reachable"
  exit 125
fi

echo "[run] docker compose run --rm kag"
docker compose run --rm kag
