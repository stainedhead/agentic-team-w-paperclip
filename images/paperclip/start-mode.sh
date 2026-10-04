#!/usr/bin/env bash
# Sourced by entrypoint.sh. Paperclip writes this config only after setup has
# reached the instance configuration step. A generated .secrets directory alone
# must not make a failed first start look initialized on the next restart.
paperclip_start_mode() {
  local home="$1" instance_id="${2:-default}"
  if [ -f "${home}/instances/${instance_id}/config.json" ]; then
    printf 'run'
  else
    printf 'onboard'
  fi
}
