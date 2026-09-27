#!/usr/bin/env bash
# Harness-only image entrypoint. Runs Hermes as the default, always-on harness (FR-004).
# Bootstrap/config-apply logic lives in harness-bootstrap.sh so images/paperclip/entrypoint.sh
# can reuse it (FR-016).
set -euo pipefail

source /opt/agentic-team/harness-bootstrap.sh

# TODO(verify): the literal foreground-run command for the Hermes gateway. Research confirmed
# `hermes gateway install` sets up a user/system *service*; running it as a container's PID 1
# likely needs a different invocation (e.g. a --foreground flag) that wasn't confirmed by
# research. Verify against Hermes's own docs before this is production-ready.
exec hermes gateway run --foreground
