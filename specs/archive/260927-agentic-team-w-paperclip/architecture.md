# Architecture: Agentic Team with Paperclip

**Created:** 2026-09-27
**Status:** Draft

## Architecture Overview

This feature's deliverable is container images + CI/CD + documentation, not a traditional
layered application — the usual Clean Architecture framing (Domain → Use Cases → Adapters)
doesn't apply. Research (2026-09-27) confirmed all four underlying tools (Hermes, OMP, OpenCode
CLI, Paperclip) are real, existing products with their own config/behavior — see `research.md`.
This narrows the architecture to three concrete pieces:

1. **Dockerfile structure** for the two image variants (FR-016) — installing existing tools, not
   writing new application logic.
2. **CI/CD pipeline structure** (FR-030/FR-031) — standard GitHub Actions → GHCR → Release
   pattern (research question 5, confirmed).
3. **The instance configuration file** (FR-017, FR-024-026) — the one genuinely new artifact this
   product introduces, since it doesn't belong to any of the four tools' own config formats. This
   is still undecided and is the one open item blocking a fully concrete Scope of Changes in
   `spec.md`.

## Component Architecture

- **Harness-only image** (`images/harness/Dockerfile`): installs Hermes (Nous Research Hermes
  Agent), OMP (oh-my-pi), and OpenCode CLI. Entrypoint runs Hermes (its gateway service), which
  owns the cron schedule.
- **Harness-plus-Paperclip image** (`images/paperclip/Dockerfile`): `FROM` the harness-only image;
  adds Paperclip; entrypoint runs both Hermes and Paperclip.
- **CI/CD pipeline** (`.github/workflows/build-and-publish.yml`): build → publish both images to
  GHCR → (on release) cut a GitHub Release.
- **Bootstrap/entrypoint logic**: on container start, checks persistent storage for the instance
  configuration file; if absent, writes defaults (FR-025); if present, reuses it (FR-026); then
  ensures Hermes/OMP/OpenCode/Paperclip's own config files are populated/updated from it (e.g.
  writing `~/.hermes/config.yaml`'s relevant fields, `~/.omp/agent/config.yml`, `OPENCODE_CONFIG`)
  so the instance config file is this product's single source of truth for the settings it
  introduces, without duplicating each tool's full native config surface.
- **The recurring Paperclip-poll job itself**: a Hermes cron job (`hermes cron create "<default
  interval>" "..."` per FR-021) whose task/script calls `paperclipai agent inbox-mine --user-id
  <id> --status todo,in_progress` (Bearer-authenticated with a Paperclip Agent API key) — this is
  the concrete mechanism behind FR-019, not a piece of custom polling code this product writes.

## Layer Responsibilities

N/A in the traditional sense. Responsibility is split as:
- **Dockerfile build logic**: installs each tool at a pinned version; no business logic.
- **Entrypoint/bootstrap scripts**: own the instance-config-file bootstrap/reuse behavior
  (FR-025/FR-026) and translate it into each tool's own config on startup.
- **CI/CD workflow definitions**: own build, publish, and release automation only — no runtime
  behavior.
- **Documentation** (`configuration-docs/`, `user-docs/`): own everything a swarm owner needs to
  configure and deploy, without this product automating that deployment (per the PRD's
  deployment-automation non-goal).

## Data Flow

Swarm owner writes the instance configuration file locally (FR-017, format `[TBD]`) → container
starts → entrypoint bootstraps default instance config if none exists on persistent storage
(FR-025), or reuses existing config (FR-026) → entrypoint applies instance config into
Hermes/OMP/OpenCode's own config files → swarm owner separately registers the agent in Paperclip
via `paperclipai agent create`/`agent hire` (FR-018) → Hermes's cron job fires on its schedule
(FR-019/FR-021) and calls `paperclipai agent inbox-mine` → work retrieved → agent works,
optionally querying/updating Jira directly (Paperclip's real OAuth Jira connector) or using `gh`
CLI directly for GitHub Projects/Issues (FR-013/FR-014/FR-033, since Paperclip's documented
GitHub connector only covers Issues) → agent updates Paperclip as system of record (FR-015, via
whatever Paperclip API/CLI surface that update uses — not yet identified beyond `agent
inbox-mine`'s read side).

## Sequence Diagrams

`[TBD — worth adding once the instance config file format is decided, to keep this concrete
rather than diagram the same prose above.]`

## Integration Points

- **Paperclip**: registration via `paperclipai agent create`/`agent hire` CLI (FR-018); work
  retrieval via `paperclipai agent inbox-mine` CLI, Bearer-authenticated with an Agent API key
  (FR-019); Jira via Paperclip's own OAuth connector (Atlassian Cloud only); GitHub via
  Paperclip's own Issues connector, supplemented by this product's `gh` CLI + PAT documentation
  for Projects access (FR-033).
- Model hosts: AWS Bedrock, Ollama Cloud, OpenRouter, Anthropic, OpenAI — per FR-009, each
  configured into whichever of Hermes/OMP/OpenCode is doing the model call.
- AWS Secrets Manager (AWS deployments) / `.env` file (local deployments) — FR-027/FR-028. Path
  convention for Secrets Manager still open (research question 3).
- GHCR, GitHub Releases — FR-030/FR-031, via standard `docker/build-push-action` +
  `GITHUB_TOKEN` (packages: write).

## Architectural Decisions

- **Decided (carried from PRD, ADR-worthy, not yet recorded in
  `documentation/architectual-decisions-record.md`)**: build the Paperclip image `FROM` the
  harness-only image (FR-016), so harness-layer changes stay in sync across both variants.
- **Decided (this phase)**: the recurring "poll Paperclip" job is implemented as a Hermes cron
  job calling Paperclip's own `agent inbox-mine` CLI — no custom polling code.
- **Decided (this phase)**: Hermes's subordinate-process orchestration of OpenCode CLI/OMP
  (FR-004) uses Hermes's generic shell/subprocess tool access — there's no named "invoke OpenCode"
  integration to configure, just a cron/agent task whose script calls the relevant CLI directly.
- **Decided (this phase, default — revisit if it doesn't hold up in implementation)**: the
  instance configuration file is a single YAML file, `/data/instance.yaml`, on the same
  persistent-storage volume as FR-024, containing only what this product introduces (not a
  restatement of any tool's own config):
  ```yaml
  personas: [Reviewer, TechLead]        # one or more of the eight PRD personas (FR-001/FR-002)
  model_host:
    provider: anthropic                 # aws_bedrock | ollama_cloud | openrouter | anthropic | openai
    credentials_ref: <env var name or Secrets Manager secret name — never a raw value, FR-027/FR-028>
  paperclip:
    agent_id: <string>                  # matches the FR-018 Paperclip registration
    api_key_ref: <env var name or Secrets Manager secret name>
  identity:
    github_bot_account_ref: <env var name or Secrets Manager secret name>  # FR-010(a)
  ```
  The entrypoint reads this on start, bootstraps it from an image-baked template if absent
  (FR-025), reuses it if present (FR-026), and applies its values into
  Hermes/OMP/OpenCode's own config files.
- **Still open**: AWS Secrets Manager path convention for the now-larger credential set
  (model-host, auth-identity, Paperclip Agent API key, GitHub PAT) — research question 3.
- **Still open**: macOS `Container` persistent-storage recipe — research question 4.
