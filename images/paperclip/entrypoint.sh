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

# TODO(verify): the actual Paperclip CLI/service start command — research confirmed Paperclip's
# API/CLI surface for agent registration and work retrieval, but not the literal command to start
# its own long-running service process. Verify against Paperclip's own deployment docs.
paperclip serve &
PAPERCLIP_PID=$!
trap 'kill -TERM "${PAPERCLIP_PID}" 2>/dev/null || true' TERM INT EXIT

exec hermes gateway run --foreground
