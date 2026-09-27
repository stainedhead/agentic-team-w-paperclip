# Harness-plus-Paperclip image (FR-016b): built FROM the harness-only image so harness-layer
# changes (Hermes/OMP/OpenCode CLI, yq, gh) stay in sync across both variants automatically.
# Adds Paperclip and runs both Hermes and Paperclip on startup.
ARG BASE_IMAGE=ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
FROM ${BASE_IMAGE}

# The harness image already dropped to a non-root USER; switch back to root for this image's own
# install step, then drop privileges again below (FR-004).
USER root

# --- Paperclip -------------------------------------------------------------------------------
# Official checksum-verified installer. A swarm owner is free to override this for their own
# build (pinned version, alternate install source, self-hosted fork, etc.).
RUN curl -fsSLO https://paperclip.ing/install.sh \
    && curl -fsSLO https://paperclip.ing/install.sh.sha256 \
    && (sha256sum -c install.sh.sha256 || shasum -a 256 -c install.sh.sha256) \
    && bash install.sh \
    && rm -f install.sh install.sh.sha256

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

USER agent

ENTRYPOINT ["/opt/agentic-team/paperclip-entrypoint.sh"]
