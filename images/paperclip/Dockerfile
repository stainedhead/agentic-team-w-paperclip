# Harness-plus-Paperclip image: built FROM the harness-only image so harness-layer
# changes (Hermes/OMP/OpenCode CLI, yq, gh) stay in sync across both variants automatically.
# Adds Paperclip and runs both Hermes and Paperclip on startup.
ARG BASE_IMAGE=ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
FROM ${BASE_IMAGE}

# The harness image already dropped to a non-root USER; switch back to root for this image's own
# install step, then drop privileges again below. Numeric, for the same reason as the 1000:1000
# switch at the end of this file.
USER 0:0

# Inherited from the base image; restated so this Dockerfile stays correct on its own if the base ever
# changes. The Paperclip install below downloads to a file rather than piping, so nothing here depends
# on pipefail today — this keeps the guarantee in place for anything added later.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Node.js major version. Paperclip's own installer declares MIN_NODE_MAJOR=20 and
# DEFAULT_NODE_MAJOR=22, so 22 is both supported and what upstream itself installs and therefore
# tests against. 24 also satisfies the minimum — override this ARG if you want it.
ARG NODE_MAJOR=22

# openssl is used by entrypoint.sh to generate BETTER_AUTH_SECRET / PAPERCLIP_TOOL_ACTION_SIGNING_SECRET
# on first boot if the swarm owner didn't supply them — not guaranteed present on the slim base.
# gnupg and ca-certificates are prerequisites for the NodeSource repository set up below.
#
# Unpinned deliberately, for the same reason as the base image's apt-get step. The ignore directive
# must be the last comment line before the instruction to take effect.
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends openssl gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# --- Node.js ---------------------------------------------------------------------------------
# Paperclip requires Node.js and does NOT bundle it: its CLI is published on npm and invoked as
# `npx paperclipai <verb>`, which is how entrypoint.sh starts it. Confirmed by CI's smoke-build job,
# where the installer reported "[paperclip] Node.js was not found" on an image without it.
#
# NodeSource is the same source Paperclip's own installer uses when it decides to install Node on a
# Debian host, so this matches upstream's choice rather than inventing one.
#
# hadolint ignore=DL3008
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" -o /tmp/nodesource_setup.sh \
    && bash /tmp/nodesource_setup.sh \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -f /tmp/nodesource_setup.sh \
    && rm -rf /var/lib/apt/lists/* \
    && node --version && npm --version && npx --version

# --- Paperclip -------------------------------------------------------------------------------
# Installed straight from npm rather than through https://paperclip.ing/install.sh.
#
# That installer cannot run in a container image, which CI's smoke-build job demonstrated: it sets
# NO_PROMPT=1 whenever stdin/stdout is not a TTY (always true during a build) and then delegates to
# `npx --yes paperclipai@latest install --no-prompt`, but the published paperclipai package rejects
# that flag — "error: unknown option '--no-prompt'". The script's only other job is installing Node,
# which the step above already did deterministically. So this skips the wrapper and installs the same
# package it would have.
#
# A swarm owner can pin a version here (paperclipai@<version>) for a reproducible build; @latest is a
# working default, consistent with how the other tools in the base image are installed.
# hadolint ignore=DL3016
RUN npm install -g paperclipai@latest \
    && npm cache clean --force

# Separate RUN (not `&&`-chained onto the install above) so a failure in the install itself still
# fails the build — chaining a trailing `|| true` onto the same statement would have silently
# masked an install failure, exactly the class of bug this fix pass exists to catch.
# This RUN executes as root but inherits HOME=/home/agent from the base image's ENV — if the
# installer wrote there (rather than to /root) it would be root-owned; re-chown to fix either
# case, best-effort.
RUN chmod -R a+rX /root; chown -R agent:agent /home/agent 2>/dev/null || true

WORKDIR /opt/agentic-team
COPY entrypoint.sh ./paperclip-entrypoint.sh
RUN chmod +x ./paperclip-entrypoint.sh && chown agent:agent ./paperclip-entrypoint.sh

# Numeric, matching the base image — see the note there.
USER 1000:1000

ENTRYPOINT ["/opt/agentic-team/paperclip-entrypoint.sh"]
