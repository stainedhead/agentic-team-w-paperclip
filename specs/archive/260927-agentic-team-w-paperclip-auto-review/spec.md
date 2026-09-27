# Spec: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Status:** Draft

## Executive Summary

This feature fixes the findings from the Step 5 code review of
`specs/archive/260927-agentic-team-w-paperclip/` (the first build of the harness/Paperclip
container images): two P0 correctness bugs that currently prevent both container images from
reaching a running state under their own shipped defaults, plus five lower-priority gaps (no
multi-arch build, containers running as root, no CI linting, a CI trigger duplication risk, and
unconfirmed cron-job idempotency).

## Problem Statement

The container images built in the prior feature do not actually run successfully under their own
shipped default configuration. The harness image's entrypoint crashes on first boot due to a
shell scripting bug (`set -e` interacting badly with an `&&`-chained conditional over optional
fields), and the harness+Paperclip image never installs or successfully starts Paperclip at all,
failing silently. Both directly violate acceptance criteria already established in
`specs/archive/260927-agentic-team-w-paperclip/spec.md`. These need fixing before the images can
be considered usable by a swarm owner.

## Goals / Non-Goals

### Goals
- Fix both P0 bugs so the containers reach a running state under their own shipped defaults.
- Add CI-level linting (shellcheck, a Dockerfile linter) so this class of bug is caught before
  merge in the future, not just found in a manual review.
- Close the P1/P2 gaps (multi-arch build, non-root user, CI trigger duplication, cron
  idempotency) where reasonably scoped to do so in this fix pass.

### Non-Goals
- Redesigning the instance-config schema, the poll mechanism, or any other decision already made
  in `specs/archive/260927-agentic-team-w-paperclip/architecture.md` — this pass fixes bugs in
  the existing design, it doesn't re-litigate the design.
- Confirming Paperclip's own install/self-host method beyond "something that actually runs" —
  the exact command remains a swarm-owner-editable default per prior direction; FR-002 only
  requires that *some* working install + loud-failure-on-crash exists, not the final answer.
- Running an actual `docker build`/`docker run` in this environment (no Docker daemon available)
  — fixes should be verified as thoroughly as static analysis (shellcheck, manual trace-through)
  allows, with a real build/run flagged as still owed.

## User Requirements

### Functional Requirements

**FR-001 (RETRACTED — not a real bug):** Originally claimed `images/harness/harness-bootstrap.sh`
exits the entrypoint whenever an optional `*_ref` field is empty/null, due to `set -e` interacting
with the `[ -n "$X" ] && [ "$X" != "null" ] && echo ...` pattern.
- **Correction (2026-09-27), verified by actually running the exact snippet in bash**: `set -e`
  only fires on the failure of the *last* command in an AND-OR list — a failing non-final element
  (either `[ ... ]` test here) is exempted regardless of position, and the list's last command
  (`echo`) essentially never fails. Reproduced with the literal snippet from
  `harness-bootstrap.sh` and confirmed exit code 0 with both optional refs empty. No fix needed;
  this finding is retracted. (Root cause of the original error: an incorrect recollection of bash's
  `set -e`/AND-OR-list exemption rule during the Step 5 review — not verified empirically at the
  time.)

**FR-002 (P0):** `images/paperclip/entrypoint.sh` shall not silently continue when the `paperclip`
process fails to start.
- Current behavior: `images/paperclip/Dockerfile`'s install step is a commented-out placeholder —
  nothing provides a `paperclip` command. `entrypoint.sh` runs `paperclip serve &` unconditionally;
  a backgrounded command's "command not found" failure does not trigger `set -e`, so the script
  proceeds to `exec hermes gateway run --foreground` as if Paperclip started successfully.

**FR-003 (P1):** CI shall build container images for the architectures this product's own
deployment targets actually need (linux/amd64 and linux/arm64).
- Current behavior: neither `docker/build-push-action` step in
  `.github/workflows/build-and-publish.yml` specifies `platforms:`, so both images build only for
  the runner's native platform (linux/amd64) — not Apple Silicon (macOS `Container`) or Graviton
  (AWS).

**FR-004 (P1):** Both images shall run their processes as a non-root user.
- Current behavior: neither Dockerfile creates or switches to a non-root `USER`. This project's
  own ADR-0002 reasons explicitly about bounding an agent's blast radius when it executes
  arbitrary code; running as container root removes a cheap, standard layer of that containment.

**FR-005 (P1):** CI shall validate the Dockerfiles and shell scripts before publishing images
built from them.
- Current behavior: the workflow builds and pushes images directly with no linting step. FR-001
  and FR-002 are exactly the class of bug a linter would have caught before merge.

**FR-006 (P2):** CI shall not double-trigger the same build/release on a tag-triggered GitHub
Release.
- Current behavior: both `push: tags: ["v*"]` and `release: types: [published]` can fire for the
  same tag.

**FR-007 (P2):** `hermes cron create`'s idempotency on repeated container restarts shall be
confirmed (and guarded against duplication if it isn't idempotent).
- Current behavior: `harness-bootstrap.sh` runs on every container start, calling `hermes cron
  create` each time; whether Hermes deduplicates an identical schedule+command is unconfirmed.

## Non-Functional Requirements

- **Reliability**: a container must reach a running state using its own shipped default
  configuration — the core bar both P0 findings currently violate.
- **Security**: FR-004 (non-root execution) — consistent with
  `documentation/architectual-decisions-record.md` ADR-0002's blast-radius reasoning.
- **Observability**: failures (like FR-002's silently-dead Paperclip process) must be visible in
  container logs/exit status, not swallowed.

## System Architecture

No architectural changes — this feature fixes bugs within the existing design from
`specs/archive/260927-agentic-team-w-paperclip/architecture.md` (image structure, instance.yaml
schema, poll mechanism all stay as decided). FR-003/FR-005 add to the CI workflow's structure
(multi-platform build args, a new lint job) without changing what it builds.

## Scope of Changes

- `images/harness/harness-bootstrap.sh` — fix the `*_ref` conditional logic (FR-001).
- `images/paperclip/Dockerfile` — install a working `paperclip` command (FR-002).
- `images/paperclip/entrypoint.sh` — fail loudly / verify Paperclip actually started (FR-002).
- `images/harness/Dockerfile`, `images/paperclip/Dockerfile` — add non-root `USER` (FR-004).
- `.github/workflows/build-and-publish.yml` — add `platforms:` + QEMU setup (FR-003), add a lint
  job for shellcheck/hadolint (FR-005), resolve the duplicate-trigger risk (FR-006).
- `images/harness/harness-bootstrap.sh` — guard `hermes cron create` against duplication if
  needed (FR-007).
- New: smoke-test script(s) verifying container startup and both-processes-running, per FR-001's
  and FR-002's acceptance criteria — exact location/tooling TBD in Process Guidance below.

## Breaking Changes

None expected — these are bug fixes to code that was never in a working state for the affected
paths (P0s), or additive CI changes (P1/P2s).

## Success Criteria and Acceptance Criteria

- [x] ~~Starting a harness or harness+Paperclip container with the unmodified default
      `instance.yaml` does not exit/crash the entrypoint.~~ Verified already true (FR-001
      retracted) — reproduced the exact snippet in bash with both optional refs empty, exit
      code 0.
- [x] ~~Leaving `paperclip.api_key_ref` and/or `identity.github_bot_account_ref` blank does not
      prevent `~/.hermes/.env` from being written with whatever fields *are* present.~~ Same
      verification as above — `.env` is written correctly with blank optional fields.
- [ ] A shellcheck-based regression test exists guarding this AND-OR-list pattern generally (not
      because this instance was buggy, but so a *future* edit that moves `echo` out of the final
      position doesn't reintroduce a real version of this class of bug unnoticed).
- [ ] The harness+Paperclip image installs a working `paperclip` command.
- [ ] If `paperclip serve` fails to start or exits, the entrypoint surfaces that failure loudly
      rather than silently continuing.
- [ ] A smoke test confirms both processes are actually running after container start.
- [ ] The workflow builds and publishes both `linux/amd64` and `linux/arm64` variants for both
      images.
- [ ] Both Dockerfiles create a non-root user, `chown` the relevant paths, and set `USER`.
- [ ] Each installed tool works correctly when invoked as a non-root user.
- [ ] A CI job runs `shellcheck` against all `.sh` files and fails on new warnings.
- [ ] A CI job runs a Dockerfile linter against both Dockerfiles.
- [ ] Only one trigger drives the release path for a given tag/release event.
- [ ] `hermes cron create`'s duplicate-call behavior is confirmed and guarded if necessary.

### Quality Gates
- [ ] All P0 findings verified fixed via TDD (failing check first, then fix, then passing).
- [ ] A brief code/design review happens after each individual fix, before starting the next.
- [ ] P0 fixed and verified before any P1/P2 work begins.

## Risks and Mitigation

| Item | Type | Notes |
|------|------|-------|
| `shellcheck` | Dependency | Needed for FR-005; ships preinstalled on `ubuntu-latest` — confirm/pin version. |
| `hadolint` | Dependency | Needed for FR-005; not preinstalled on `ubuntu-latest` — needs its own setup step or container-based action. |
| QEMU / Buildx multi-platform support | Dependency | Needed for FR-003; `docker/setup-qemu-action` alongside the existing `docker/setup-buildx-action`. |
| No Docker daemon in this environment | Risk | Fixes for FR-001/FR-002 can be verified via static reasoning (shellcheck, manual trace-through) but not an actual `docker build`/`run` here — real verification is still owed once a daemon is available. |
| Paperclip's real install method still unknown | Risk | FR-002's acceptance criteria only require *a* working install, not the confirmed-correct one. |

## Timeline and Milestones

`[TBD — see tasks.md once broken down; P0s first, then P1/P2s per the Process Guidance below.]`

## Process Guidance for Implementing Fixes

(Carried from the review PRD, since it's specifically required for a review-PRD-derived spec.)

- **TDD (Red → Green → Refactor)** for every fix: write a failing check first, confirm it fails
  against the current code, then fix, then confirm it passes.
- **A brief code/design review after each individual fix**, before moving to the next.
- **Fix P0 first, then P1, then P2** — do not start P1/P2 work before both P0 bugs are fixed and
  verified.
- **Agent teammates / git worktrees**: FR-001–FR-002 (bash logic) and FR-003–FR-004
  (Dockerfile/CI changes) touch disjoint files and can be parallelized across worktrees/teammates
  if useful; FR-005 (CI linting) should land after FR-001/FR-002 are fixed, so the new lint job
  has real fixed code to validate against.

## References

- Source PRD: `specs/260927-agentic-team-w-paperclip-auto-review/agentic-team-w-paperclip-auto-review-PRD.md`
- Prior spec (findings originate from its build): `specs/archive/260927-agentic-team-w-paperclip/`
- `documentation/architectual-decisions-record.md` — ADR-0002 (blast-radius reasoning behind
  FR-004), ADR-0006/0007/0008/0009 (design this fix pass must not re-litigate).
