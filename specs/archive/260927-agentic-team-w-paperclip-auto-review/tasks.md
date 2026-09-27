# Tasks: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Status:** Complete

## Progress Summary

6/6 tasks complete (P1.1 retracted — not a real bug, no fix needed).

## Phase 1: P0 Fixes

- **P1.1 (RETRACTED)** — ~~Fix `images/harness/harness-bootstrap.sh`'s optional-`*_ref`
  handling (FR-001)~~ — verified via actual bash reproduction that no bug exists; no fix needed.
  See `spec.md`'s FR-001 correction.

- **P1.2 (Complete)** — Fix `images/paperclip/Dockerfile` + `entrypoint.sh` so Paperclip
  actually runs or fails loudly (FR-002)
  - Real install command (checksum-verified installer) supplied by the user and added to the
    Dockerfile. `entrypoint.sh` now checks `command -v paperclip` before starting it (fails
    loudly if missing) and verifies the process is still alive one second after starting
    (fails loudly if it died immediately), replacing the prior silent-failure behavior.
  - Remaining unverified: the literal `paperclip serve` start command and any required boot-time
    env vars/config — flagged as a TODO in the entrypoint pending Paperclip's own deployment docs.

## Phase 2: P1 Fixes

- **P2.1 (Complete)** — Added multi-arch (`linux/amd64`,`linux/arm64`) build to
  `.github/workflows/build-and-publish.yml` (FR-003), via `docker/setup-qemu-action` +
  `platforms:` on both build-push-action steps.

- **P2.2 (Complete)** — Added non-root `USER agent` (UID/GID 1000:1000, matching this project's
  existing convention) to both Dockerfiles (FR-004), with `/root` widened to read+execute and a
  best-effort copy of any root-installed dotfiles/config into the new user's home — flagged as
  unverified without a real `docker build` (no daemon available in this environment).

- **P2.3 (Complete)** — Added a `lint` CI job (shellcheck + hadolint on both Dockerfiles) that
  gates `build-and-publish` (FR-005), landed after P1.2 per the dependency ordering.

## Phase 3: P2 Fixes

- **P3.1 (Complete)** — Removed the `push: tags: [...]` trigger (kept only
  `push: branches: [main]` and `release: types: [published]`), and removed the now-redundant
  separate "create a release" job — a release already exists by the time `release: published`
  fires (FR-006).

- **P3.2 (Complete)** — Added an explicit idempotency guard in `harness-bootstrap.sh`: checks
  `~/.hermes/cron/jobs.json` for the exact poll command before calling `hermes cron create`,
  rather than relying on unconfirmed dedup behavior from Hermes itself (FR-007).
