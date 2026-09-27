# Harness-plus-Paperclip image (FR-016b): built FROM the harness-only image so harness-layer
# changes (Hermes/OMP/OpenCode CLI, yq, gh) stay in sync across both variants automatically.
# Adds Paperclip and runs both Hermes and Paperclip on startup.
ARG BASE_IMAGE=ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
FROM ${BASE_IMAGE}

# --- Paperclip -------------------------------------------------------------------------------
# Default install step below — a swarm owner is free to override it for their own build (pinned
# version, alternate install source, self-hosted fork, etc.). See configuration-docs/ for the
# documented pattern this follows.
# RUN <install paperclip here — default pending confirmation, see configuration-docs/>

WORKDIR /opt/agentic-team
COPY entrypoint.sh ./paperclip-entrypoint.sh
RUN chmod +x ./paperclip-entrypoint.sh

ENTRYPOINT ["/opt/agentic-team/paperclip-entrypoint.sh"]
