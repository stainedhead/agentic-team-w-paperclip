# Plan: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27
**Status:** Planning

## Development Approach

Fix P0s first (FR-001, FR-002), each with TDD (failing check → fix → passing check) and a brief
review before moving on. Then P1s (FR-003, FR-004, FR-005), then P2s (FR-006, FR-007). Per the
Process Guidance in `spec.md`, FR-001/FR-002 (bash logic) and FR-003/FR-004 (Dockerfile/CI) touch
disjoint files and can be parallelized; FR-005 (linting) should land after FR-001/FR-002 are
fixed so the new lint rules validate against already-correct code.

## Phase Breakdown

1. **P0 fixes**: FR-001, FR-002 — with smoke tests as the "Red" step of TDD where no daemon is
   available (shellcheck + manual trace-through standing in for a real run).
2. **P1 fixes**: FR-003 (multi-arch), FR-004 (non-root), FR-005 (CI linting, after P0s land).
3. **P2 fixes**: FR-006 (CI trigger dedup), FR-007 (cron idempotency guard).

## Critical Path

FR-001 and FR-002 block everything else per the Process Guidance's "P0 first" rule. FR-005
specifically depends on FR-001/FR-002 being fixed first (linting a rule against still-broken code
isn't meaningful).

## Testing Strategy

No Docker daemon available in this environment. Testing relies on:
- `shellcheck` against the fixed `.sh` files (can run without a daemon).
- Manual trace-through of the `set -e`/AND-OR-list logic (documented in the finding) to confirm
  the fix actually changes the failure mode.
- A smoke-test script's logic reviewed for correctness even if it can't be executed here.
- Flag clearly in `implementation-notes.md` that a real `docker build && docker run` pass is still
  owed once a daemon is available.

## Rollout Strategy

Same as the prior spec — these are fixes to unreleased, unpublished images (no image has actually
been through a real CI build yet), so there's no rollback/migration concern for existing running
containers.

## Success Metrics

See `spec.md`'s Acceptance Criteria and Quality Gates.
