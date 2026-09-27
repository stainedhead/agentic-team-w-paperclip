#!/usr/bin/env bash
# Start one agent instance under the macOS `container` runtime.
#
# Usage:
#   ./run-instance.sh <agent-name> [harness|paperclip]
#
# Example:
#   ./run-instance.sh reviewer-01
#   ./run-instance.sh orchestrator-01 paperclip
#
# Creates ~/agentic-team/<agent-name>/data as the persistent volume for /data, expects a filled-in
# .env alongside it, and starts the container. On first start the container writes a default
# instance.yaml into that data directory for you to edit.
#
# This is a starting point to adapt, not a supported deployment tool — this project documents
# deployment rather than automating it.
set -euo pipefail

AGENT_NAME="${1:-}"
VARIANT="${2:-harness}"
REGISTRY="ghcr.io/stainedhead/agentic-team-w-paperclip"
INSTANCE_ROOT="${INSTANCE_ROOT:-${HOME}/agentic-team}"

if [ -z "${AGENT_NAME}" ]; then
  echo "usage: $0 <agent-name> [harness|paperclip]" >&2
  exit 1
fi

case "${VARIANT}" in
  harness|paperclip) ;;
  *) echo "error: variant must be 'harness' or 'paperclip', got '${VARIANT}'" >&2; exit 1 ;;
esac

AGENT_DIR="${INSTANCE_ROOT}/${AGENT_NAME}"
DATA_DIR="${AGENT_DIR}/data"
ENV_FILE="${AGENT_DIR}/.env"
IMAGE="${REGISTRY}/${VARIANT}:latest"

mkdir -p "${DATA_DIR}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "error: no ${ENV_FILE}" >&2
  echo "       copy templates/env/.env.example (or .env.paperclip.example for the paperclip" >&2
  echo "       variant) there and fill it in first." >&2
  exit 1
fi

echo "==> starting ${AGENT_NAME}"
echo "    image:  ${IMAGE}"
echo "    volume: ${DATA_DIR} -> /data"
echo "    env:    ${ENV_FILE}"

# --detach so the container keeps running after this script exits; drop it to watch startup logs
# in the foreground instead.
container run --detach \
  --name "${AGENT_NAME}" \
  --volume "${DATA_DIR}:/data" \
  --env-file "${ENV_FILE}" \
  "${IMAGE}"

cat <<EOF

Started. Next steps:

  1. Edit the instance configuration written on first start:
       ${DATA_DIR}/instance.yaml
     (set personas, model_host, and paperclip.agent_id — see
      user-docs/configuration-reference.md)

  2. Restart so your edits are applied:
       container stop ${AGENT_NAME} && container start ${AGENT_NAME}

  3. Check it came up:
       container logs ${AGENT_NAME}
EOF
