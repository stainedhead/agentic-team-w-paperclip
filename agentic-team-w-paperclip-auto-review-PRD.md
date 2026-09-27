# PRD: Agentic Team with Paperclip — Code & Design Review Findings

**Created:** 2026-09-27
**Jira:** N/A
**Status:** Draft
**Source:** Review of `feat/agentic-team-w-paperclip` vs `main`
(`specs/260927-agentic-team-w-paperclip/`)

## Executive Summary

The branch delivers what the spec asked for structurally — two Dockerfiles with a base-image
relationship, an entrypoint/bootstrap script implementing the config-bootstrap-and-reuse pattern,
a CI/CD workflow, and documentation aligned with the actual build. However, review found **two
P0 correctness bugs that would prevent the containers from running at all under their own
shipped defaults**: the harness image's bootstrap script crashes on startup whenever an optional
credential reference is unset (which is true of the shipped default template itself), and the
Paperclip image never actually installs or successfully starts Paperclip, despite the entrypoint
unconditionally trying to run it. Both are silent/crash failures that directly contradict
acceptance criteria already in `spec.md`. No automated tests, linting, or an actual `docker build`
run have verified any of this end-to-end (no Docker daemon was available during implementation).
Additional P1/P2 findings cover a missing multi-arch build (contradicting the macOS `Container`
Apple Silicon / AWS Graviton targets), containers running fully as root, CI trigger duplication,
and unverified `hermes cron create` idempotency.

## Findings

**FR-001 (P0):** `images/harness/harness-bootstrap.sh` shall not exit the entrypoint process when
an optional `*_ref` field (`paperclip.api_key_ref`, `identity.github_bot_account_ref`) is empty or
`"null"`.
- **Current behavior**: lines 33–36 use the pattern `[ -n "$X" ] && [ "$X" != "null" ] && echo
  ...` as a bare statement. Under `set -euo pipefail`, when the first or second test is false,
  this compound command's own exit status is non-zero, which is not exempted from `set -e` at the
  top level (only intermediate commands inside an `if`/`while` condition are exempted) — so the
  script exits immediately. This reproduces with the **shipped `instance.default.yaml` itself**
  (`identity.github_bot_account_ref: ""`), meaning the container crashes on its very first boot.
- **Acceptance criteria**:
  - [ ] Starting a harness or harness+Paperclip container with the unmodified default
    `instance.yaml` (as bootstrapped from `instance.default.yaml`) does not exit/crash the
    entrypoint.
  - [ ] Leaving `paperclip.api_key_ref` and/or `identity.github_bot_account_ref` blank does not
    prevent `~/.hermes/.env` from being written with whatever fields *are* present.
  - [ ] A regression test (shellcheck and/or a scripted smoke test) exists that exercises the
    bootstrap logic with an instance config missing these optional fields.

**FR-002 (P0):** `images/paperclip/entrypoint.sh` shall not silently continue when the `paperclip`
process fails to start.
- **Current behavior**: `images/paperclip/Dockerfile` never installs anything providing a
  `paperclip` command (the install step is a commented-out placeholder). `entrypoint.sh` runs
  `paperclip serve &` unconditionally; a backgrounded command's "command not found" failure does
  not trigger `set -e`, so the script proceeds to `exec hermes gateway run --foreground` as if
  Paperclip started successfully. The container reports as healthy while Paperclip is not
  running at all — directly contradicting FR-016's requirement that both processes run.
- **Acceptance criteria**:
  - [ ] The harness+Paperclip image installs a working `paperclip` command (even a documented,
    swarm-owner-overridable default is acceptable per prior direction — but *something* that
    runs, not a fully commented-out no-op).
  - [ ] If `paperclip serve` fails to start or exits, the entrypoint surfaces that failure
    loudly (non-zero exit, or at minimum a clearly-flagged error in the container's logs) rather
    than silently continuing as if nothing happened.
  - [ ] A smoke test confirms both processes are actually running after container start (e.g.
    checking for both PIDs), not just that the container itself is still up.

**FR-003 (P1):** CI shall build container images for the architectures this product's own
deployment targets actually need.
- **Current behavior**: `.github/workflows/build-and-publish.yml`'s two `docker/build-push-action`
  steps specify no `platforms:`, so both images build only for the GitHub-hosted runner's native
  platform (linux/amd64). `configuration-docs/deploy-macos-container.md` targets Apple Silicon
  (arm64) Macs, and `documentation/technical-architecture.md` targets AWS Graviton (arm64) — an
  amd64-only image doesn't run natively on either without emulation.
- **Acceptance criteria**:
  - [ ] The workflow builds and publishes both `linux/amd64` and `linux/arm64` variants for both
    images (e.g. via `platforms: linux/amd64,linux/arm64` plus QEMU/Buildx multi-platform setup).
  - [ ] `configuration-docs/deploy-macos-container.md` and `deploy-ecs-fargate.md` reference the
    correct multi-arch manifest tags (no change needed if Docker's standard multi-arch manifest
    list is used — same tag resolves per-platform automatically).

**FR-004 (P1):** Both images shall run their processes as a non-root user.
- **Current behavior**: neither `images/harness/Dockerfile` nor `images/paperclip/Dockerfile`
  creates or switches to a non-root `USER` — everything (Hermes, OMP, OpenCode CLI, Paperclip)
  runs as root. This project's own `documentation/architectual-decisions-record.md` (ADR-0002)
  reasons explicitly about bounding an agent's blast radius when it executes arbitrary code;
  running as container root removes a cheap, standard layer of that containment.
- **Acceptance criteria**:
  - [ ] Both Dockerfiles create a non-root user, `chown` `/opt/agentic-team` and the `/data`
    mount point to it, and set `USER` before the entrypoint runs.
  - [ ] Confirm each installed tool (Hermes, OMP, OpenCode CLI, Paperclip) actually works when
    invoked as a non-root user (some install scripts assume root — verify during the still-owed
    real `docker build`/run test).

**FR-005 (P1):** CI shall validate the Dockerfiles and shell scripts before publishing images
built from them.
- **Current behavior**: the workflow builds and pushes images directly; nothing lints or
  statically checks `images/*/Dockerfile` or `images/*/*.sh` first. FR-001/FR-002 above are
  exactly the class of bug (a shell logic error, a Dockerfile step that's a no-op) that a linter
  would have caught before merge.
- **Acceptance criteria**:
  - [ ] A CI job runs `shellcheck` against `harness-bootstrap.sh`, both `entrypoint.sh` files, and
    fails the build on new warnings.
  - [ ] A CI job runs a Dockerfile linter (e.g. `hadolint`) against both Dockerfiles.
  - [ ] These checks run before (or gate) the build-and-publish job.

**FR-006 (P2):** CI shall not double-trigger the same build/release on a tag-triggered GitHub
Release.
- **Current behavior**: both `push: tags: ["v*"]` and `release: types: [published]` can fire for
  the same tag (publishing a release also sets `github.ref` to the tag), so `build-and-publish`
  (and potentially the `release` job's `if` condition) can run twice for one release event.
- **Acceptance criteria**:
  - [ ] Only one of the two triggers drives the release path (commonly `release: types:
    [published]` alone), or an explicit guard prevents the duplicate run.

**FR-007 (P2):** `hermes cron create`'s idempotency on repeated container restarts shall be
confirmed.
- **Current behavior**: `harness-bootstrap.sh` runs on every container start (not just the first
  one), calling `hermes cron create` each time. Whether Hermes deduplicates an identical
  schedule+command or accumulates a new job on every restart is unconfirmed (already flagged as a
  TODO in-code) — if it accumulates, a frequently-restarted instance would end up polling
  Paperclip many times per interval instead of once.
- **Acceptance criteria**:
  - [ ] Confirm against Hermes's own behavior (or `~/.hermes/cron/jobs.json` contents after
    multiple restarts) whether duplicate `cron create` calls are deduplicated.
  - [ ] If not, guard the call (e.g. check `jobs.json` for an existing matching entry before
    creating another).

## Notes

- Findings FR-001 and FR-002 are Must Fix / blockers — the containers do not currently reach a
  running state under their own shipped defaults for the harness image, and Paperclip never
  actually runs in the harness+Paperclip image.
- No fixes have been implemented as part of this review — per the review process, this document
  is findings-only.
