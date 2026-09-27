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
A single YAML file, `/data/instance.yaml`, on the persistent-storage volume (FR-024) — separate
from Hermes's own `~/.hermes/config.yaml`, OMP's `~/.omp/agent/config.yml`, and OpenCode's
`OPENCODE_CONFIG*`. See `architecture.md`'s Architectural Decisions for the concrete schema:
`personas` (list), `model_host` (provider + credentials_ref), `paperclip` (agent_id +
api_key_ref), `identity` (github_bot_account_ref). All `*_ref` fields are names/paths, never raw
credential values (FR-027/FR-028).

### Paperclip Roster Entry (FR-011, FR-018)
Not this product's data to define — it's Paperclip's own internal representation, created via
`paperclipai agent create`/`agent hire` (CLI) or its UI. This product only needs to know the
*inputs* to that registration (agent identity, persona/role) and the *retrieval* command
(`paperclipai agent inbox-mine --user-id <id> --status todo,in_progress`, Bearer-authenticated
with an Agent API key) that a Hermes cron job calls for FR-019. Staleness/heartbeat tracking
behind FR-022 is Paperclip's own concern (see spec.md's Edge Case Handling scope boundary).

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
- `HERMES` = Nous Research's Hermes Agent ([github.com/NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent))
- `OMP` = oh-my-pi ([github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi))
- `OPENCODE_CLI` = OpenCode CLI ([opencode.ai](https://opencode.ai/docs/cli/))

### Deployment Target (FR-006-008)
`MACOS_CONTAINER | ECS_FARGATE | EKS`

## API Request/Response Types

`[TBD]`
