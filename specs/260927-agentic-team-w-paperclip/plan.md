# Plan: Agentic Team with Paperclip

**Created:** 2026-09-27
**Status:** Planning

## Development Approach

`[TBD]` — pending architecture.md. Expected shape: research the real Hermes/OMP/OpenCode
CLI/Paperclip surfaces first (research.md questions 1-2), then build the harness-only image,
then the harness-plus-Paperclip image on top of it (per FR-016's layering requirement), then
CI/CD, then documentation.

## Phase Breakdown

`[TBD]`

## Critical Path

`[TBD]` — likely: research questions 1 and 2 (actual Hermes/Paperclip surfaces) block everything
else, since the Dockerfiles and bootstrap logic depend on knowing what these tools actually need.

## Testing Strategy

`[TBD]` — no traditional domain/use-case unit-test layers apply here. Expected shape: Dockerfile
build tests (images build successfully), smoke tests (container starts, Hermes/Paperclip
processes come up, default config bootstraps on first run), and CI workflow validation (images
land in GHCR, a release can be cut).

## Rollout Strategy

`[TBD]`

## Success Metrics

See `spec.md`'s Acceptance Criteria and Quality Gates.
