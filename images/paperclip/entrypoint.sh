#!/usr/bin/env bash
# Harness-plus-Paperclip image entrypoint. Runs both Hermes and Paperclip on startup (FR-016),
# reusing the harness image's bootstrap/config-apply logic.
#
# NOTE: this is a minimal two-process container (no init system / process supervisor like tini
# or s6-overlay). It's a reasonable starting point for FR-016's requirement, but a production
# deployment may want a real supervisor so a crashed Paperclip process is both detected and
# restarted rather than just torn down with the container. Flagged in implementation-notes.md.
set -euo pipefail

# Reuse the harness image's config bootstrap + Hermes config-apply logic — everything up to (but
# not including) its final `exec hermes gateway run`.
source /opt/agentic-team/harness-bootstrap.sh

# Verified 2026-09-27 against Paperclip's own README/doc/DOCKER.md (raw source, not a summarizer):
# the CLI is invoked as `npx paperclipai <verb>`, not a bare `paperclip` command, and there is no
# `paperclip serve` — first run does `onboard --yes` (installs/initializes/starts), subsequent
# runs do `run`. PAPERCLIP_HOME is its persistent data dir; point it at our own /data volume
# (FR-024) so Paperclip's state persists the same way instance.yaml does, rather than a separate
# untracked directory. Postgres is embedded by default (no DATABASE_URL needed to boot).
export HOST="${HOST:-0.0.0.0}"
export PAPERCLIP_HOME="${PAPERCLIP_HOME:-/data/paperclip}"
mkdir -p "${PAPERCLIP_HOME}"

# Decide onboard-vs-run BEFORE writing anything into PAPERCLIP_HOME below (including the
# generated-secrets file) — otherwise this directory would never look "empty" on first boot and
# 'run' would always be chosen instead of 'onboard', breaking first-run initialization entirely.
NEEDS_ONBOARD=0
if [ -z "$(ls -A "${PAPERCLIP_HOME}" 2>/dev/null)" ]; then
  NEEDS_ONBOARD=1
fi

# BETTER_AUTH_SECRET and PAPERCLIP_TOOL_ACTION_SIGNING_SECRET are required just to boot, and must
# stay stable across restarts (they sign sessions/tokens) — so generate them once on first start
# and persist to PAPERCLIP_HOME rather than regenerating randomly every boot, unless the swarm
# owner already supplied them via the container's own environment (e.g. from `.env`/Secrets
# Manager, same pattern as this product's other credentials).
SECRETS_FILE="${PAPERCLIP_HOME}/.generated-secrets.env"
if [ -z "${BETTER_AUTH_SECRET:-}" ] || [ -z "${PAPERCLIP_TOOL_ACTION_SIGNING_SECRET:-}" ]; then
  if [ -f "${SECRETS_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${SECRETS_FILE}"
  else
    echo "[entrypoint] generating BETTER_AUTH_SECRET / PAPERCLIP_TOOL_ACTION_SIGNING_SECRET" \
         "(not supplied, no prior generated copy found) — persisting to ${SECRETS_FILE}"
    {
      echo "export BETTER_AUTH_SECRET=$(openssl rand -hex 32)"
      echo "export PAPERCLIP_TOOL_ACTION_SIGNING_SECRET=$(openssl rand -hex 32)"
    } > "${SECRETS_FILE}"
    # shellcheck disable=SC1090
    source "${SECRETS_FILE}"
  fi
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "[entrypoint] FATAL: no 'npx' command found on PATH — Paperclip's install did not" >&2
  echo "[entrypoint] succeed (it's invoked as 'npx paperclipai <verb>', not a bare binary)." >&2
  exit 1
fi

if [ "${NEEDS_ONBOARD}" -eq 1 ]; then
  npx paperclipai onboard --yes &
else
  npx paperclipai run &
fi
PAPERCLIP_PID=$!
sleep 1
if ! kill -0 "${PAPERCLIP_PID}" 2>/dev/null; then
  echo "[entrypoint] FATAL: Paperclip exited immediately after starting — it is not running." >&2
  echo "[entrypoint] Refusing to continue with it silently missing." >&2
  exit 1
fi
trap 'kill -TERM "${PAPERCLIP_PID}" 2>/dev/null || true' TERM INT EXIT

exec hermes gateway run --foreground
