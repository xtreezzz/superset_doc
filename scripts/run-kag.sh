#!/usr/bin/env bash
set -euo pipefail

: "${TARGET_REPO_URL:=https://github.com/apache/superset.git}"
: "${TARGET_REPO_DIR:=/workspace/src/superset}"
: "${OUTPUT_DIR:=/workspace/output}"
: "${KG_COMMAND:=knowledge-graph --help}"
: "${SKIP_CLONE:=0}"
: "${ALLOW_FALLBACK_GRAPH:=1}"

RUN_DIR="${OUTPUT_DIR}/run-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${RUN_DIR}"
LOG_FILE="${RUN_DIR}/run.log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "[kag] start: $(date -Iseconds)"
echo "[kag] output run dir: ${RUN_DIR}"
echo "[kag] target repo dir: ${TARGET_REPO_DIR}"

if [ "${SKIP_CLONE}" != "1" ]; then
  if [ ! -d "${TARGET_REPO_DIR}/.git" ]; then
    echo "[kag] cloning ${TARGET_REPO_URL} -> ${TARGET_REPO_DIR}"
    git clone --depth 1 "${TARGET_REPO_URL}" "${TARGET_REPO_DIR}"
  else
    echo "[kag] repository already exists at ${TARGET_REPO_DIR}, pulling latest"
    git -C "${TARGET_REPO_DIR}" pull --ff-only
  fi
else
  echo "[kag] SKIP_CLONE=1, using existing directory"
fi

if [ ! -d "${TARGET_REPO_DIR}" ]; then
  echo "[kag] ERROR: repository directory not found: ${TARGET_REPO_DIR}"
  exit 2
fi

cd "${TARGET_REPO_DIR}"

FALLBACK_SCRIPT="${FALLBACK_SCRIPT:-}"
if [ -z "${FALLBACK_SCRIPT}" ]; then
  if [ -f "/workspace/scripts/generate_fallback_kag.py" ]; then
    FALLBACK_SCRIPT="/workspace/scripts/generate_fallback_kag.py"
  elif [ -f "$(dirname "$0")/generate_fallback_kag.py" ]; then
    FALLBACK_SCRIPT="$(dirname "$0")/generate_fallback_kag.py"
  elif [ -f "${TARGET_REPO_DIR}/scripts/generate_fallback_kag.py" ]; then
    FALLBACK_SCRIPT="${TARGET_REPO_DIR}/scripts/generate_fallback_kag.py"
  fi
fi

if command -v knowledge-graph >/dev/null 2>&1; then
  echo "[kag] running command: ${KG_COMMAND}"
  /bin/bash -lc "${KG_COMMAND}"
else
  if [ "${ALLOW_FALLBACK_GRAPH}" = "1" ] && [ -n "${FALLBACK_SCRIPT}" ]; then
    echo "[kag] knowledge-graph not found, generating fallback graph"
    python3 "${FALLBACK_SCRIPT}" \
      --root "${TARGET_REPO_DIR}" \
      --output "${RUN_DIR}/fallback-kag.json"
    cat > "${RUN_DIR}/kag_status.txt" <<STATUS
knowledge-graph binary was not found in PATH.
Generated fallback graph instead: ${RUN_DIR}/fallback-kag.json
STATUS
  else
    cat > "${RUN_DIR}/kag_status.txt" <<STATUS
knowledge-graph binary was not found in PATH and fallback script was not found.
Install it in the image (set INSTALL_KG_FROM_GITLAB=1 with network access),
mount/provide the binary in PATH, or set FALLBACK_SCRIPT.
STATUS
    echo "[kag] ERROR: knowledge-graph binary not found"
    exit 3
  fi
fi

git rev-parse HEAD > "${RUN_DIR}/target_repo_head.txt" || true
echo "[kag] done: $(date -Iseconds)"
echo "[kag] artifacts in: ${RUN_DIR}"
