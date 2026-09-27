# Implementation Notes: Agentic Team with Paperclip — Code & Design Review Fixes

**Created:** 2026-09-27

Purpose: a running log of decisions, edge cases, and deviations discovered during
implementation — not a plan restated. Update this file as work happens, not after the fact.

## Technical Decisions

- **FR-001 retracted (2026-09-27)**: while starting TDD's "Red" step (reproducing the claimed
  bug before fixing it), the exact `harness-bootstrap.sh` snippet was run in real bash with both
  optional `*_ref` fields empty — it completed successfully (exit 0), not the crash the Step 5
  review claimed. Root cause of the original review error: `set -e` only aborts on the failure of
  the *last* command in an `&&`/`||` list; a failing earlier element (either `[ ... ]` test here)
  is exempted regardless of position — confirmed with three isolated test cases before accepting
  the correction. No fix applied; see `spec.md`'s FR-001 entry for the full writeup.
- **FR-002's Paperclip install command** confirmed directly by the user: a checksum-verified
  installer script (`curl` two files, `sha256sum`/`shasum` verify, `bash install.sh`) — used as-is
  in `images/paperclip/Dockerfile` rather than a guessed command.
- **Self-caught bug while implementing FR-002/FR-004**: my first draft appended
  `&& chown -R agent:agent /home/agent 2>/dev/null || true` directly onto the end of the
  install/user-creation `&&` chains. Verified empirically (same technique as the FR-001
  retraction) that a trailing `|| true` on a whole chain masks failures from *any* earlier
  command in that chain, not just the one it was meant to guard — e.g. a failed `bash
  install.sh` would have been silently swallowed, reporting build success. Fixed by splitting
  the best-effort chown into its own separate `RUN` instruction in both Dockerfiles, so a real
  install/setup failure still fails the build. Lesson: verify `&&`/`||` chain semantics
  empirically before trusting them, especially when adding a trailing best-effort fallback to an
  existing chain — this is the second time in this fix pass alone that assumption vs. reality
  diverged on this exact class of shell logic.

## Edge Cases & Solutions

`[TBD]`

## Deviations from Plan

`[TBD]`

## Lessons Learned

`[TBD]`
