#!/usr/bin/env bash
# Harness-only image entrypoint. Runs Hermes as the default, always-on harness.
# Bootstrap/config-apply logic lives in harness-bootstrap.sh so images/paperclip/entrypoint.sh
# can reuse it.
set -euo pipefail

# shellcheck source=harness-bootstrap.sh
source /opt/agentic-team/harness-bootstrap.sh

# Single process, so exec into it directly — Hermes becomes PID 1 and receives the container's
# signals itself, with no supervisor needed. (The harness+Paperclip variant runs two processes and
# therefore cannot do this; see images/paperclip/entrypoint.sh and ADR-0013.)
#
# TODO(verify): the literal foreground-run command for the Hermes gateway. Research confirmed
# `hermes gateway install` sets up a user/system *service*; running it as a container's PID 1
# likely needs a different invocation (e.g. a --foreground flag) that wasn't confirmed by
# research. Verify against Hermes's own docs before this is production-ready.
exec hermes gateway run --foreground
