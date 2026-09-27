# Harness-only image: installs Hermes, OMP, and OpenCode CLI; runs Hermes on startup as the
# always-on harness. Built from Debian slim (glibc) since Hermes's own installer bootstraps uv/Python and
# expects a standard glibc environment, not musl/Alpine.
FROM debian:bookworm-slim

# Prerequisites for the tool installers below, plus yq (YAML read/write used by
# harness-bootstrap.sh) and the GitHub CLI. git/tar are required by Hermes's and
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
# specs/archive/260927-agentic-team-w-paperclip/research.md. The script clones the repo via git and
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

# Run as a non-root user at runtime (UID/GID 1000:1000, this project's convention — ADR-0002). The
# installers above ran as root and may have placed binaries under /root's default install locations
# (e.g. ~/.local/bin, the usual convention for curl-based CLI installers), so widen /root to
# read+execute — not write — to keep those reachable after dropping privileges.
RUN groupadd -g 1000 agent && useradd -u 1000 -g 1000 -m -d /home/agent -s /bin/bash agent \
    && chmod -R a+rX /root
# Best-effort copy of whatever dotfiles/config the installers above wrote under /root — kept as
# its own RUN (rather than `&&`-chained with a trailing `|| true`, which would mask a real
# failure in the group/user creation above) so a missing/empty /root/.* glob can't silently mask
# an unrelated failure.
RUN cp -r /root/.[!.]* /home/agent/ 2>/dev/null; true
RUN chown -R agent:agent /home/agent \
    && mkdir -p /data && chown -R agent:agent /opt/agentic-team /data
# Set on ENV (not in a shell rc file, which wouldn't apply to a non-login container process). Both
# HOMEs' bin directories are listed because the installers ran as root, writing under /root, while
# the runtime user's HOME is /home/agent — the dotfile copy above may leave a binary in either.
# UNVERIFIED without a Docker daemon: CI's smoke-build job is what asserts every tool is actually
# reachable here after the privilege drop.
ENV PATH="/home/agent/.local/bin:/home/agent/.opencode/bin:/root/.local/bin:${PATH}" \
    HOME=/home/agent
USER agent

ENTRYPOINT ["/opt/agentic-team/entrypoint.sh"]
