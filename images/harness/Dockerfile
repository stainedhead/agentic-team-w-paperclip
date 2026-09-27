# Harness-only image (FR-016a): installs Hermes, OMP, and OpenCode CLI; runs Hermes on startup
# (FR-004). Built from Debian slim rather than Alpine since all three tools are more likely to
# ship glibc-linked binaries/npm packages than musl-compatible ones.
FROM debian:bookworm-slim

# Prerequisites for the tool installers below, plus yq (YAML read/write used by
# harness-bootstrap.sh) and the GitHub CLI (FR-033).
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip nodejs npm \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture) \
         -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

# --- Hermes (Nous Research Hermes Agent) ---------------------------------------------------
# The exact install command is an environment-specific detail a swarm owner supplies/confirms for
# their own build (version pin, install source, etc.) — this product's job is to document the
# pattern, not guarantee one exact command. See configuration-docs/ for the documented example;
# replace the line below with the swarm owner's actual install step.
# RUN <install hermes here — see configuration-docs/>

# --- OMP (oh-my-pi) -------------------------------------------------------------------------
# Same note as Hermes above — see configuration-docs/ for the documented example.
# RUN <install omp here — see configuration-docs/>

# --- OpenCode CLI ---------------------------------------------------------------------------
# Confirmed install methods exist (curl script, npm, pnpm, bun, brew — opencode.ai/docs/cli), but
# the exact npm package name below is not yet confirmed against the docs. Using npm since Node.js
# is already a prerequisite above; verify the package name before this build is trusted.
# TODO(verify): confirm exact npm package name against opencode.ai/docs/cli.
RUN npm install -g opencode-ai

WORKDIR /opt/agentic-team
COPY instance.default.yaml harness-bootstrap.sh entrypoint.sh ./
RUN chmod +x harness-bootstrap.sh entrypoint.sh

ENTRYPOINT ["/opt/agentic-team/entrypoint.sh"]
