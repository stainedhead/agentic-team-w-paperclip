# Architecture: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Status:** Draft

## Architecture Overview

No architectural changes. This fix pass corrects implementation bugs within the design already
decided in `specs/archive/260927-agentic-team-w-paperclip/architecture.md` (image structure,
`instance.yaml` schema, Hermes-cron-calls-Paperclip-CLI poll mechanism). See that file for the
design this pass must not re-litigate (per this spec's Non-Goals).

## Component Architecture

Unchanged component boundaries:
- `images/harness/` (Dockerfile, entrypoint.sh, harness-bootstrap.sh, instance.default.yaml)
- `images/paperclip/` (Dockerfile, entrypoint.sh)
- `.github/workflows/build-and-publish.yml`

New within this pass: a CI lint job (FR-005), smoke-test script(s) for FR-001/FR-002's acceptance
criteria — location TBD, likely `images/*/smoke-test.sh` or a shared `scripts/smoke-test.sh`
parameterized by image.

## Layer Responsibilities

Unchanged — see the prior spec's architecture.md.

## Data Flow

Unchanged — see the prior spec's architecture.md. This pass doesn't change how data flows, only
fixes bugs in how the bootstrap/entrypoint logic handles that data (FR-001) and what actually
runs as a result (FR-002).

## Sequence Diagrams

`[TBD]`

## Integration Points

Unchanged.

## Architectural Decisions

- **Decision (this phase)**: fixes are scoped to correctness, not redesign — confirmed by this
  spec's Non-Goals. Any temptation to change the `instance.yaml` schema, poll mechanism, or image
  layering while fixing these bugs should be resisted; file a new ADR/spec instead if a real
  design change turns out to be necessary.
