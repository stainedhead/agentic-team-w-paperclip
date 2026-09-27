# Implementation Notes: Agentic Team with Paperclip

**Created:** 2026-09-27

Purpose: a running log of decisions, edge cases, and deviations discovered during
implementation — not a plan restated. Update this file as work happens, not after the fact.

## Technical Decisions

- **AWS Secrets Manager path convention**: reuses ADR-0002's per-agent path scheme
  (`/agents/${AGENT_ID}/*`) for model-host, Paperclip Agent API key, and GitHub PAT credentials —
  one secret per credential per agent, e.g. `/agents/${AGENT_ID}/model-host-api-key`. Documented
  as a default the swarm owner can change (e.g. a shared model-host key across agents) as long as
  the container-environment mapping still matches `instance.yaml`'s `*_ref` names.
- **macOS `Container` persistent-storage recipe**: a plain host-directory bind mount via
  `container run --volume <host-dir>:/data`, matching Docker's own `-v` semantics. Documented in
  `configuration-docs/deploy-macos-container.md`.
- **Tool install steps in the Dockerfiles are defaults, not guarantees**: per explicit user
  direction, the exact install command for Hermes, OMP, and Paperclip inside `images/*/Dockerfile`
  are swarm-owner-editable defaults, not something this product hard-verifies or blocks the build
  on. Where a command isn't yet confirmed from the tool's own docs, the Dockerfile carries a
  comment marking it as a default pending confirmation, not a hard build failure.
- **Hermes/OMP/OpenCode CLI install commands verified 2026-09-27** by fetching each tool's actual
  install script (not just doc summaries) — `images/harness/Dockerfile` uses the confirmed
  commands. Paperclip's own install/self-host method is still unconfirmed (out of scope for that
  research pass) and remains a commented placeholder in `images/paperclip/Dockerfile`.
- No Docker daemon was available in this environment to actually run `docker build` against
  either Dockerfile — the install commands are sourced from each tool's real script, but the
  build itself is unverified end-to-end. Flagged in `research.md`'s Open Questions.

## Edge Cases & Solutions

See `spec.md`'s "Edge Case Handling (Scope Boundary)" — tool-internal failure behavior (poll
retries, credential failures, duplicate identity, corrupted state) is explicitly out of scope;
each tool owns its own.

## Deviations from Plan

- Step 3 (per the dev-flow pipeline) does not use Clean Architecture Domain/Use Case/Adapter
  layers, per the scoping discussion before implementation began — the deliverable is Dockerfiles,
  an entrypoint/bootstrap script, a CI/CD workflow, and documentation.

## Lessons Learned

- A background research agent inheriting a fork's conversation context can get confused by a
  pending/rejected question earlier in that context and fail to do its actual task (returned a
  bare clarifying question instead of a research report). Fresh, context-free agents with a
  fully self-contained prompt were more reliable for pure research tasks in this session.
