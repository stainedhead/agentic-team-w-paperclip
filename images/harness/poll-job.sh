#!/usr/bin/env bash
# Reconcile the one Paperclip inbox job managed by this image. Use Hermes's CLI
# for mutations so its cron store remains consistent with the running gateway.
reconcile_paperclip_poll_job() {
  local jobs_file="$1" schedule="$2" agent_id="$3"
  local command="paperclipai agent inbox-mine --user-id ${agent_id} --status todo,in_progress"
  local managed_ids="" selected="" id="" saved_prompt="" saved_schedule=""

  if [ -f "${jobs_file}" ]; then
    if ! managed_ids="$(jq -r '
      .jobs[]?
      | select((.prompt // "")
          | startswith("paperclipai agent inbox-mine --user-id ")
            and endswith(" --status todo,in_progress"))
      | .id // empty
    ' "${jobs_file}" 2>/dev/null)"; then
      echo "[bootstrap] WARNING: cannot read Hermes cron jobs; leaving poll jobs unchanged" >&2
      return 1
    fi
  fi

  if [ -n "${managed_ids}" ]; then
    while IFS= read -r id; do
      saved_prompt="$(jq -r --arg id "${id}" '.jobs[]? | select(.id == $id) | .prompt // ""' "${jobs_file}")" || return 1
      if [ "${saved_prompt}" = "${command}" ] && [ -n "${agent_id}" ]; then
        selected="${id}"
        break
      fi
    done <<< "${managed_ids}"
  fi

  if [ -z "${agent_id}" ]; then
    echo "[bootstrap] paperclip.agent_id is unset — removing any previous Paperclip poll job"
  elif [ -z "${selected}" ] && [ -n "${managed_ids}" ]; then
    IFS= read -r selected <<< "${managed_ids}"
  fi

  if [ -n "${selected}" ]; then
    saved_prompt="$(jq -r --arg id "${selected}" '.jobs[]? | select(.id == $id) | .prompt // ""' "${jobs_file}")" || return 1
    saved_schedule="$(jq -r --arg id "${selected}" '.jobs[]? | select(.id == $id) | .schedule.expr? // .schedule_display // ""' "${jobs_file}")" || return 1
    if [ "${saved_prompt}" != "${command}" ] || [ "${saved_schedule}" != "${schedule}" ]; then
      echo "[bootstrap] updating Paperclip poll job ${selected}"
      hermes cron edit "${selected}" --schedule "${schedule}" --prompt "${command}" || return 1
    else
      echo "[bootstrap] Paperclip poll job is current"
    fi
  elif [ -n "${agent_id}" ]; then
    echo "[bootstrap] registering Paperclip poll job on schedule '${schedule}'"
    hermes cron create "${schedule}" "${command}" || return 1
  fi

  if [ -n "${managed_ids}" ]; then
    while IFS= read -r id; do
      if [ "${id}" != "${selected}" ]; then
        echo "[bootstrap] removing stale Paperclip poll job ${id}"
        hermes cron remove "${id}" || return 1
      fi
    done <<< "${managed_ids}"
  fi
}
