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

if ! command -v paperclip >/dev/null 2>&1; then
  echo "[entrypoint] FATAL: no 'paperclip' command found on PATH — the image build did not" >&2
  echo "[entrypoint] install it successfully. Refusing to start with Paperclip silently missing." >&2
  exit 1
fi

# TODO(verify): `paperclip serve` is the assumed start command; confirm against Paperclip's own
# deployment docs once available (research covered registration/work-retrieval, not the literal
# server-start invocation).
paperclip serve &
PAPERCLIP_PID=$!
sleep 1
if ! kill -0 "${PAPERCLIP_PID}" 2>/dev/null; then
  echo "[entrypoint] FATAL: 'paperclip serve' exited immediately after starting — Paperclip is" >&2
  echo "[entrypoint] not running. Refusing to continue with it silently missing." >&2
  exit 1
fi
trap 'kill -TERM "${PAPERCLIP_PID}" 2>/dev/null || true' TERM INT EXIT

exec hermes gateway run --foreground
