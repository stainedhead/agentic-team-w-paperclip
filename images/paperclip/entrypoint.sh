#!/usr/bin/env bash
# Harness-plus-Paperclip image entrypoint. Runs both Hermes and Paperclip on startup, reusing the
# harness image's bootstrap/config-apply logic.
#
# This script stays PID 1 and acts as a minimal supervisor: it forwards shutdown signals to both
# children and exits when either one dies, so a crashed process is visible to the orchestrator's
# restart policy instead of silently disappearing. It deliberately does NOT restart a child — see
# documentation/architectual-decisions-record.md ADR-0013 for why exiting is the better default
# under ECS/Kubernetes/`container`, and what to reach for if in-container restarts are wanted.
set -euo pipefail

# Reuse the harness image's config bootstrap + env-generation logic.
# shellcheck source=../harness/harness-bootstrap.sh
source /opt/agentic-team/harness-bootstrap.sh

# Verified 2026-09-27 against Paperclip's own README/doc/DOCKER.md (raw source, not a summarizer):
# the CLI is invoked as `npx paperclipai <verb>`, not a bare `paperclip` command, and there is no
# `paperclip serve` — an instance without config does `onboard --yes` (initializes/starts), while a
# configured instance does `run`. PAPERCLIP_HOME is its persistent data dir; point it at /data so
# Paperclip's state persists the same way instance.yaml does, rather than a separate untracked
# directory. Postgres is embedded by default (no DATABASE_URL needed to boot).
export HOST="${HOST:-0.0.0.0}"
export PAPERCLIP_HOME="${PAPERCLIP_HOME:-/data/paperclip}"
mkdir -p "${PAPERCLIP_HOME}"

# shellcheck source=start-mode.sh
source /opt/agentic-team/paperclip-start-mode.sh
PAPERCLIP_START_MODE="$(paperclip_start_mode "${PAPERCLIP_HOME}" "${PAPERCLIP_INSTANCE_ID:-default}")"

# BETTER_AUTH_SECRET and PAPERCLIP_TOOL_ACTION_SIGNING_SECRET are required just to boot, and must
# stay stable across restarts (they sign sessions/tokens) — so generate them once on first start
# and persist to PAPERCLIP_HOME rather than regenerating randomly every boot, unless the swarm
# owner already supplied them via the container's own environment (e.g. from `.env`/Secrets
# Manager, same pattern as this product's other credentials).
#
# Each secret is handled independently: an earlier version regenerated/overwrote BOTH whenever
# EITHER was missing, which silently clobbered a swarm-owner-supplied value with a generated one.
SECRETS_DIR="${PAPERCLIP_HOME}/.secrets"
mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

# Echoes the secret's resolved value on stdout; all logging goes to stderr so the caller can
# capture the value cleanly. $1 is the name (for the persisted filename and log lines), $2 is
# whatever the container's environment already supplied for it.
resolve_secret() {
  local var_name="$1" supplied="${2:-}" secret_file="${SECRETS_DIR}/$1"
  # Supplied by the environment — always wins, and is never persisted to the volume here.
  if [ -n "${supplied}" ]; then
    echo "[entrypoint] ${var_name}: using the value supplied in this container's environment" >&2
    printf '%s' "${supplied}"
    return 0
  fi
  if [ -f "${secret_file}" ]; then
    echo "[entrypoint] ${var_name}: reusing the value generated on a previous start" >&2
  else
    echo "[entrypoint] ${var_name}: not supplied and no prior value found — generating one and" \
         "persisting it to ${secret_file}" >&2
    (umask 077; openssl rand -hex 32 > "${secret_file}")
  fi
  cat "${secret_file}"
}

BETTER_AUTH_SECRET="$(resolve_secret BETTER_AUTH_SECRET "${BETTER_AUTH_SECRET:-}")"
PAPERCLIP_TOOL_ACTION_SIGNING_SECRET="$(resolve_secret PAPERCLIP_TOOL_ACTION_SIGNING_SECRET \
  "${PAPERCLIP_TOOL_ACTION_SIGNING_SECRET:-}")"
export BETTER_AUTH_SECRET PAPERCLIP_TOOL_ACTION_SIGNING_SECRET

if ! command -v npx >/dev/null 2>&1; then
  echo "[entrypoint] FATAL: no 'npx' command found on PATH — Paperclip cannot start, since its" >&2
  echo "[entrypoint] CLI is invoked as 'npx paperclipai <verb>' rather than a bare binary." >&2
  echo "[entrypoint] Add a Node.js runtime to images/paperclip/Dockerfile and rebuild." >&2
  exit 1
fi

# --- start both processes ---------------------------------------------------------------------
if [ "${PAPERCLIP_START_MODE}" = "onboard" ]; then
  echo "[entrypoint] first start for ${PAPERCLIP_HOME} — running 'paperclipai onboard'"
  npx paperclipai onboard --yes &
else
  echo "[entrypoint] existing Paperclip data found — running 'paperclipai run'"
  npx paperclipai run &
fi
PAPERCLIP_PID=$!

sleep 1
if ! kill -0 "${PAPERCLIP_PID}" 2>/dev/null; then
  echo "[entrypoint] FATAL: Paperclip exited immediately after starting — it is not running." >&2
  echo "[entrypoint] Refusing to continue with it silently missing." >&2
  exit 1
fi

# TODO(verify): the literal foreground-run command for the Hermes gateway. Research confirmed
# `hermes gateway install` sets up a user/system *service*; running it as a container process
# likely needs a different invocation (e.g. a --foreground flag) that wasn't confirmed by
# research. Verify against Hermes's own docs before this is production-ready.
hermes gateway run --foreground &
HERMES_PID=$!

stop_children() {
  kill -TERM "${PAPERCLIP_PID}" "${HERMES_PID}" 2>/dev/null || true
}

SHUTDOWN_REQUESTED=0
# shellcheck disable=SC2317  # reached via the `trap` below, which shellcheck cannot see
on_signal() {
  SHUTDOWN_REQUESTED=1
  echo "[entrypoint] shutdown signal received — forwarding TERM to Paperclip and Hermes"
  stop_children
}
trap on_signal TERM INT

echo "[entrypoint] supervising Paperclip (pid ${PAPERCLIP_PID}) and Hermes (pid ${HERMES_PID})"

# Block until either child exits. This polls rather than using `wait -n` so it does not depend on
# bash >= 4.3 — which also makes it testable outside the image, on a host whose /bin/bash is older.
# A forwarded signal interrupts the sleep and runs the trap, after which both children are gone and
# the loop falls through on its own.
while kill -0 "${PAPERCLIP_PID}" 2>/dev/null && kill -0 "${HERMES_PID}" 2>/dev/null; do
  sleep 1
done

# On a requested shutdown both children are already being stopped, so "which one died first" is not
# a meaningful distinction — don't imply one of them crashed.
if [ "${SHUTDOWN_REQUESTED}" -eq 1 ]; then
  DIED="shutdown requested; Paperclip and Hermes"
elif kill -0 "${HERMES_PID}" 2>/dev/null; then
  DIED="Paperclip"
else
  DIED="the Hermes gateway"
fi

stop_children

# Reap both so their exit statuses are available; a child that has already exited still yields its
# status here.
set +e
wait "${PAPERCLIP_PID}"; PAPERCLIP_STATUS=$?
wait "${HERMES_PID}";    HERMES_STATUS=$?
set -e

if [ "${DIED}" = "Paperclip" ]; then
  EXIT_STATUS="${PAPERCLIP_STATUS}"
else
  EXIT_STATUS="${HERMES_STATUS}"
fi

echo "[entrypoint] ${DIED} exited (status ${EXIT_STATUS}) — stopped the other process and exiting," \
     "so the orchestrator's restart policy can act on this"
exit "${EXIT_STATUS}"
