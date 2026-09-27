# Tasks: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Status:** Planning

## Progress Summary

0/7 tasks complete.

## Phase 1: P0 Fixes

- **P1.1** — Fix `images/harness/harness-bootstrap.sh`'s optional-`*_ref` handling (FR-001)
  - **Dependencies:** none
  - **Duration:** `[TBD]`
  - **Acceptance criteria:** starting a container with the unmodified default `instance.yaml`
    does not exit/crash the entrypoint; `~/.hermes/.env` is written with whatever fields *are*
    present even when optional ones are blank.

- **P1.2** — Fix `images/paperclip/Dockerfile` + `entrypoint.sh` so Paperclip actually
  runs or fails loudly (FR-002)
  - **Dependencies:** none
  - **Duration:** `[TBD]`
  - **Acceptance criteria:** the image installs a working `paperclip` command; a failed/missing
    Paperclip process surfaces loudly rather than silently continuing; a smoke test confirms both
    processes are running.

## Phase 2: P1 Fixes

- **P2.1** — Add multi-arch (`linux/amd64`,`linux/arm64`) build to
  `.github/workflows/build-and-publish.yml` (FR-003)
  - **Dependencies:** none
  - **Duration:** `[TBD]`

- **P2.2** — Add non-root `USER` to both Dockerfiles (FR-004)
  - **Dependencies:** none
  - **Duration:** `[TBD]`

- **P2.3** — Add a CI lint job for shellcheck/hadolint (FR-005)
  - **Dependencies:** P1.1, P1.2 (fix P0s first so lint rules validate against correct code)
  - **Duration:** `[TBD]`

## Phase 3: P2 Fixes

- **P3.1** — Resolve duplicate CI trigger on release (FR-006)
  - **Dependencies:** none
  - **Duration:** `[TBD]`

- **P3.2** — Confirm/guard `hermes cron create` idempotency (FR-007)
  - **Dependencies:** none
  - **Duration:** `[TBD]`
