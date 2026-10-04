#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../images/harness/poll-job.sh
source "${repo_root}/images/harness/poll-job.sh"
# shellcheck source=../images/paperclip/start-mode.sh
source "${repo_root}/images/paperclip/start-mode.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
export HERMES_TEST_CALLS="${tmp}/calls"
mkdir -p "${tmp}/bin"
cat > "${tmp}/bin/hermes" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${HERMES_TEST_CALLS}"
EOF
chmod +x "${tmp}/bin/hermes"
export PATH="${tmp}/bin:${PATH}"
jobs="${tmp}/jobs.json"
command='paperclipai agent inbox-mine --user-id agent-1 --status todo,in_progress'

assert_calls() {
  local want="$1" got
  got="$(wc -l < "${HERMES_TEST_CALLS}" | tr -d ' ')"
  if [ "${got}" != "${want}" ]; then
    echo "expected ${want} Hermes calls, got ${got}" >&2
    cat "${HERMES_TEST_CALLS}" >&2
    exit 1
  fi
}

: > "${HERMES_TEST_CALLS}"
reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' agent-1
assert_calls 1
grep -Fx "cron create */5 * * * * ${command}" "${HERMES_TEST_CALLS}"

cat > "${jobs}" <<EOF
{"jobs":[{"id":"job-1","prompt":"${command}","schedule":{"expr":"*/5 * * * *"}}]}
EOF
: > "${HERMES_TEST_CALLS}"
reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' agent-1
assert_calls 0

reconcile_paperclip_poll_job "${jobs}" '*/2 * * * *' agent-1
assert_calls 1
grep -Fx "cron edit job-1 --schedule */2 * * * * --prompt ${command}" "${HERMES_TEST_CALLS}"

: > "${HERMES_TEST_CALLS}"
reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' agent-2
assert_calls 1
grep -Fq 'cron edit job-1 --schedule */5 * * * * --prompt paperclipai agent inbox-mine --user-id agent-2' "${HERMES_TEST_CALLS}"

cat > "${jobs}" <<EOF
{"jobs":[{"id":"job-1","prompt":"${command}","schedule":{"expr":"*/5 * * * *"}},{"id":"job-2","prompt":"paperclipai agent inbox-mine --user-id old --status todo,in_progress","schedule":{"expr":"*/5 * * * *"}}]}
EOF
: > "${HERMES_TEST_CALLS}"
reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' agent-1
assert_calls 1
grep -Fx 'cron remove job-2' "${HERMES_TEST_CALLS}"

: > "${HERMES_TEST_CALLS}"
reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' ''
assert_calls 2
grep -Fx 'cron remove job-1' "${HERMES_TEST_CALLS}"
grep -Fx 'cron remove job-2' "${HERMES_TEST_CALLS}"

printf '%s\n' 'not json' > "${jobs}"
: > "${HERMES_TEST_CALLS}"
if reconcile_paperclip_poll_job "${jobs}" '*/5 * * * *' agent-1; then
  echo 'malformed cron jobs should fail without creating a duplicate' >&2
  exit 1
fi
assert_calls 0

home="${tmp}/paperclip"
mkdir -p "${home}/.secrets"
[ "$(paperclip_start_mode "${home}" default)" = onboard ]
mkdir -p "${home}/instances/default"
printf '%s\n' '{}' > "${home}/instances/default/config.json"
[ "$(paperclip_start_mode "${home}" default)" = run ]
[ "$(paperclip_start_mode "${home}" other)" = onboard ]

echo 'startup helper tests passed'
