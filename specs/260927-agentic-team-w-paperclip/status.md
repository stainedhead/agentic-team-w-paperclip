# Status: Agentic Team with Paperclip

**Created:** 2026-09-27

## Overall Progress

| Phase | Name | Status |
|---|---|---|
| 0 | Spec Creation | Complete |
| 1 | Research | Complete |
| 2 | Data Modeling | In Progress |
| 3 | Architecture | In Progress |
| 4 | Implementation | Not Started |
| 5 | Tests | Not Started |

## Phase 0 Task Checklist

- [x] Spec created from `agentic-team-w-paperclip-PRD.md`
- [x] Research questions identified (see `research.md`)
- [x] Phase files initialized (`spec.md`, `status.md`, `research.md`, `data-dictionary.md`,
      `architecture.md`, `plan.md`, `tasks.md`, `implementation-notes.md`)

## Phase 1 (Research) Task Checklist

- [x] Confirmed Hermes = Nous Research's Hermes Agent, OMP = oh-my-pi, OpenCode CLI = opencode.ai
      (all real, install/config surfaces documented in `research.md`)
- [x] Confirmed Paperclip's real registration/work-retrieval/auth mechanisms
- [x] Confirmed Paperclip's GitHub connector covers Issues, not Projects — narrowed this
      product's deliverable to `gh` CLI/PAT configuration docs (FR-033) instead of a specific
      connector guarantee
- [x] Confirmed GitHub Actions → GHCR → Release is the standard, current CI/CD pattern
- [ ] AWS Secrets Manager path convention for the full credential set — still open
- [ ] macOS `Container` persistent-storage recipe — still open
- [ ] OMP install method — not confirmed from docs fetched, needs direct verification

## Phase 2/3 (Data Modeling / Architecture) Task Checklist

- [x] Instance configuration file format decided (`/data/instance.yaml`, schema in
      `architecture.md`)
- [x] Poll mechanism decided: Hermes cron job → `paperclipai agent inbox-mine` CLI
- [x] Image structure decided: `images/harness/Dockerfile`, `images/paperclip/Dockerfile` (FROM
      harness image)
- [ ] Sequence diagrams — not yet written
- [ ] FR-016's base-image-layering decision still needs recording in
      `documentation/architectual-decisions-record.md`

## Blockers

None currently. Three remaining open items (AWS Secrets Manager path convention, macOS
`Container` persistent-storage recipe, OMP install verification) are implementation-detail
research, not architecture-blocking.

## Recent Activity

- 2026-09-27: Spec directory `specs/260927-agentic-team-w-paperclip/` created from PRD via
  `/create-spec`.
- 2026-09-27: `/review-spec` run; found Fail on edge-case handling and Warnings on technical
  approach/component coverage.
- 2026-09-27: Resolved edge-case handling by documenting an explicit scope boundary (tool-internal
  behavior is each tool's own concern, not this product's).
- 2026-09-27: Background research confirmed the real identities and install/config/API surfaces
  of Hermes, OMP, OpenCode CLI, and Paperclip; resolved most of the technical-approach and
  component-coverage gaps as a result. Corrected the GitHub Projects vs. Issues assumption and
  narrowed FR-033's deliverable accordingly.
