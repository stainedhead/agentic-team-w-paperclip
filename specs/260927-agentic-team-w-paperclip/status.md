# Status: Agentic Team with Paperclip

**Created:** 2026-09-27

## Overall Progress

| Phase | Name | Status |
|---|---|---|
| 0 | Spec Creation | Complete |
| 1 | Research | Complete |
| 2 | Data Modeling | In Progress |
| 3 | Architecture | In Progress |
| 4 | Implementation | Complete |
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

## Phase 4 (Implementation) Task Checklist

- [x] `images/harness/Dockerfile`, `harness-bootstrap.sh`, `entrypoint.sh`,
      `instance.default.yaml`
- [x] `images/paperclip/Dockerfile`, `entrypoint.sh` (FROM harness image)
- [x] `.github/workflows/build-and-publish.yml` (build both images, publish to GHCR, release job)
- [x] `configuration-docs/github-cli-and-pat.md` (FR-033)
- [x] `configuration-docs/credentials-and-secrets.md` extended with concrete env var / Secrets
      Manager path convention
- [x] `configuration-docs/deploy-macos-container.md`, `deploy-ecs-fargate.md`, `deploy-eks.md`
      (FR-032) — macOS persistent-storage open question resolved
- [x] Confirm exact install commands for Hermes, OMP, and OpenCode CLI (verified against each
      tool's actual install script; `images/harness/Dockerfile` updated accordingly)
- [ ] Confirm Paperclip's own install/self-host method (still a commented placeholder in
      `images/paperclip/Dockerfile`)
- [ ] Run an actual `docker build` against both Dockerfiles to verify end-to-end (no Docker
      daemon available in this environment during implementation)
- [x] `documentation/architectual-decisions-record.md` — recorded ADR-0006 (FR-016 base-image
      layering), ADR-0007 (poll mechanism), ADR-0008 (instance.yaml), ADR-0009 (Secrets Manager
      path convention)

## Blockers

None currently. Paperclip's own install/self-host method remains an unconfirmed, swarm-owner-
editable default in `images/paperclip/Dockerfile`. A real `docker build` test is still owed once
a Docker daemon is available.

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
- 2026-09-27: Brought the PRD (inside this spec directory) to parity with spec.md's refinements.
- 2026-09-27: Step 3 (Implement Product) started — Dockerfiles, entrypoint/bootstrap scripts,
  CI/CD workflow, and configuration-docs (credentials, GitHub PAT, deployment examples for all
  three targets) written. Resolved the AWS Secrets Manager path convention and macOS
  persistent-storage recipe open questions.
- 2026-09-27: Background research verified the exact install commands for Hermes, OMP, and
  OpenCode CLI against each tool's actual install script; `images/harness/Dockerfile` updated
  accordingly. Paperclip's own install method remains an unconfirmed, swarm-owner-editable
  default.
- 2026-09-27: Recorded ADR-0006 through ADR-0009 in
  `documentation/architectual-decisions-record.md`. Step 3 (Implement Product) complete.
- 2026-09-27: Step 4 (Documentation and User Docs) — updated `documentation/product-summary.md`,
  `product-details.md`, and `technical-architecture.md` (added a "what's actually built" section
  distinguishing it from the original enterprise-draft target design) to reflect the real build;
  updated root `README.md`; wrote `user-docs/getting-started.md`, `configuration-reference.md`,
  and `usage-examples.md`, replacing the placeholder `user-docs/README.md`.
