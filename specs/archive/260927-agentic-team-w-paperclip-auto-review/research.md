# Research: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Source PRD:** `specs/260927-agentic-team-w-paperclip-auto-review/agentic-team-w-paperclip-auto-review-PRD.md`

## Research Questions

1. **Is a real `docker build`/`docker run` test available for this fix pass?** No Docker daemon
   was available during the original implementation or its review. If one becomes available
   before/during this fix pass, fixes should be verified end-to-end, not just via static analysis.
2. **`hadolint` availability on `ubuntu-latest` GitHub-hosted runners** — does it need an explicit
   install step, or should its own Docker-based GitHub Action be used instead? Affects how FR-005
   is implemented.
3. **`shellcheck` version on `ubuntu-latest`** — confirm what ships preinstalled vs. whether a
   specific version should be pinned for reproducibility.
4. **Does Hermes's `cron create` command dedupe an identical schedule+command, or does repeated
   calls accumulate duplicate jobs?** Directly determines whether FR-007 needs an explicit guard
   or is already safe.
5. **Paperclip's actual install/self-host command** — still unconfirmed (carried from
   `specs/archive/260927-agentic-team-w-paperclip/research.md`). FR-002 only requires *a* working
   default, but confirming the real command would let that default also be correct.

## Industry Standards

`[TBD]`

## Existing Implementations

`[TBD — investigate hadolint's recommended CI integration pattern, and Docker's official
multi-platform build guide (buildx + QEMU) for FR-003.]`

## API Documentation

`[TBD]`

## Best Practices

`[TBD]`

## Open Questions

- All five research questions above remain open as of spec creation.

## References

- `agentic-team-w-paperclip-auto-review-PRD.md` (this spec directory)
- `specs/archive/260927-agentic-team-w-paperclip/research.md` (prior spec's research, including
  the still-open Paperclip install question)
- `documentation/architectual-decisions-record.md`
