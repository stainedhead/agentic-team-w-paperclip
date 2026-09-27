# Harness-only image (FR-016a): installs Hermes, OMP, and OpenCode CLI; runs Hermes on startup
# (FR-004). Built from Debian slim (glibc) since Hermes's own installer bootstraps uv/Python and
# expects a standard glibc environment, not musl/Alpine.
FROM debian:bookworm-slim

# Prerequisites for the tool installers below, plus yq (YAML read/write used by
# harness-bootstrap.sh) and the GitHub CLI (FR-033). git/tar are required by Hermes's and
# OpenCode's install scripts respectively (see per-tool notes below).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git tar \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture) \
         -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

# --- Hermes (Nous Research Hermes Agent) ---------------------------------------------------
# Verified 2026-09-27 against the actual install script (not just docs) — see
# specs/260927-agentic-team-w-paperclip/research.md. The script clones the repo via git and
# bootstraps its own uv/Python runtime, so it needs network access during build and `git` as a
# prerequisite (installed above). --non-interactive skips setup/gateway prompts, needed for a
# non-interactive Docker build. This is a default the swarm owner can replace (e.g. to pin a
# specific Hermes version) for their own build.
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive

# --- OMP (oh-my-pi) -------------------------------------------------------------------------
# Verified 2026-09-27 against the actual install script. Self-contained; only needs curl (already
# installed above). Default the swarm owner can replace for their own build.
RUN curl -fsSL https://omp.sh/install | sh

# --- OpenCode CLI ---------------------------------------------------------------------------
# Verified 2026-09-27 against the actual install script. The curl-script path downloads a
# prebuilt binary (linux-arm64/linux-x64) — no Node/npm needed, so npm/nodejs are deliberately
# NOT in this image's prerequisites. Default the swarm owner can replace (e.g. `npm i -g
# opencode-ai@latest` if they'd rather pin an npm version — that route needs Node/npm added
# above).
RUN curl -fsSL https://opencode.ai/install | bash

WORKDIR /opt/agentic-team
COPY instance.default.yaml harness-bootstrap.sh entrypoint.sh ./
RUN chmod +x harness-bootstrap.sh entrypoint.sh

ENTRYPOINT ["/opt/agentic-team/entrypoint.sh"]
