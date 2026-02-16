#!/usr/bin/env bash
set -euo pipefail

: "${TARGET_REPO_URL:=https://github.com/apache/superset.git}"
: "${TARGET_REPO_DIR:=/workspace/src/superset}"
: "${OUTPUT_DIR:=/workspace/output}"
: "${KG_COMMAND:=knowledge-graph --help}"
: "${SKIP_CLONE:=0}"

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

if ! command -v knowledge-graph >/dev/null 2>&1; then
  cat > "${RUN_DIR}/kag_status.txt" <<STATUS
knowledge-graph binary was not found in PATH.
Install it in the image (set INSTALL_KG_FROM_GITLAB=1 with network access)
or mount/provide the binary in PATH before running.
STATUS
  echo "[kag] ERROR: knowledge-graph binary not found"
  exit 3
fi

echo "[kag] running command: ${KG_COMMAND}"
/bin/bash -lc "${KG_COMMAND}"

git rev-parse HEAD > "${RUN_DIR}/target_repo_head.txt" || true
echo "[kag] done: $(date -Iseconds)"
echo "[kag] artifacts in: ${RUN_DIR}"
