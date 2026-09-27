# Data Dictionary: Agentic Team with Paperclip

**Created:** 2026-09-27

Purpose: define the data structures implied by the PRD's requirements — instance configuration,
Paperclip roster entries, and persona definitions — so implementation has a single agreed shape
to build against. All entries below are placeholders pending the Architecture phase; field names
and types are not final.

## Entities

### Persona (FR-001)
`[TBD]` — one of: CTO, Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian.

### Harness Instance Configuration (FR-002, FR-009, FR-010, FR-017, FR-024-026)
`[TBD]` — persisted locally on the instance; expected to include: assigned persona(s), model-host
selection + reference to credentials (not raw values, see FR-027/FR-028), authentication identity
reference, and any Hermes/OMP/OpenCode-specific settings.

### Paperclip Roster Entry (FR-011, FR-018)
`[TBD]` — registered separately from the harness instance's own local config; expected to pair a
harness instance identity with its persona/role, plus whatever staleness/heartbeat tracking
backs FR-022.

### Work Item (FR-011, FR-013-015)
`[TBD]` — a unit of assigned work, sourced from Paperclip's native items, Jira, or GitHub
Projects, with a status that Paperclip treats as the system of record (FR-015).

## Value Objects

`[TBD]`

## Interfaces

`[TBD — depends on research question 2 (Paperclip's actual API/config surface).]`

## Enumerations

### Model Host (FR-009)
`AWS_BEDROCK | OLLAMA_CLOUD | OPENROUTER | ANTHROPIC | OPENAI`

### Harness Type (FR-003)
`HERMES | OMP | OPENCODE_CLI`

### Deployment Target (FR-006-008)
`MACOS_CONTAINER | ECS_FARGATE | EKS`

## API Request/Response Types

`[TBD]`
