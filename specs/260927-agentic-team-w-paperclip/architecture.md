# Architecture: Agentic Team with Paperclip

**Created:** 2026-09-27
**Status:** Draft

## Architecture Overview

`[TBD]` — this feature's deliverable is container images + CI/CD + documentation, not a
traditional layered application. The usual Clean Architecture framing (Domain → Use Cases →
Adapters) doesn't map cleanly; this section should instead define: the Dockerfile structure for
the two image variants (FR-016), the CI/CD pipeline structure (FR-030/FR-031), and the
configuration file format an instance reads/writes (FR-017, FR-024-026).

## Component Architecture

`[TBD]`
- Harness-only image (Hermes + OMP + OpenCode CLI, Hermes runs on startup)
- Harness-plus-Paperclip image (built `FROM` harness-only image, adds Paperclip, both run on
  startup)
- CI/CD pipeline (build → publish to GHCR → release)
- Configuration/bootstrap logic (default-config write on first start, reuse on update)

## Layer Responsibilities

`[TBD — n/a in the traditional sense; use this section to assign responsibility across:
Dockerfile build logic, entrypoint/bootstrap scripts, CI/CD workflow definitions, and
documentation generation, once research questions 1, 2, and 5 are answered.]`

## Data Flow

`[TBD]`
- Swarm owner configures instance locally (FR-017) → instance bootstraps default config on first
  start if none exists (FR-025) → swarm owner registers agent in Paperclip (FR-018) → instance
  polls Paperclip on its cron schedule (FR-019/FR-021) → work retrieved → agent works, optionally
  querying/updating Jira or GitHub Projects directly (FR-013/FR-014) → agent updates Paperclip as
  system of record (FR-015).

## Sequence Diagrams

`[TBD]`

## Integration Points

- Paperclip (roster registration, polling) — pending research question 2.
- Jira API, GitHub Projects API — direct query/update per FR-013/FR-014.
- Model hosts: AWS Bedrock, Ollama Cloud, OpenRouter, Anthropic, OpenAI — per FR-009.
- AWS Secrets Manager (AWS deployments) / `.env` file (local deployments) — FR-027/FR-028.
- GHCR, GitHub Releases — FR-030/FR-031.

## Architectural Decisions

`[TBD — FR-016's decision to build the Paperclip image FROM the harness-only image is already
flagged in the PRD as ADR-worthy but not yet recorded in
documentation/architectual-decisions-record.md. Record it here first, then propagate to the ADR
log per AGENTS.md's routing table once this spec's architecture stabilizes.]`
