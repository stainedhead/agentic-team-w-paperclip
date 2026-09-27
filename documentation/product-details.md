# Product Details

> Scope note: everything below reflects the AWS-hosted design drafted in `../initial-context.md`.
> Local-mode is not yet designed (see [INTENT.md](../INTENT.md)).

## Components
- **Orchestration & Collaboration Plane** — a Paperclip AI instance that manages organization
  structure, agent heartbeats, project graphs, budgets, and developer collaboration.
- **Worker Fleet** — long-running agent workers, each running a distinct persona (e.g. Security
  Auditor, Database Architect, QA Automation), built on a shared runtime toolchain: Hermes,
  OpenCode CLI, and OMP.

## Developer-facing workflow
- Developers authenticate via Okta SSO and use a Paperclip web dashboard.
- Developers can review active worktrees, view agent budget/token burn rates, assign new issues,
  and invoke specific personas via `@agent-name`.
- Paperclip dispatches context to the addressed worker over private service discovery and
  orchestrates downstream review loops with other worker agents.

## Isolation model
- Each worker persona runs under its own IAM task role, confining the blast radius of anything it
  executes (e.g. the QA agent cannot reach production data stores; the DB Architect agent cannot
  modify IAM).
- Each worker's filesystem access is confined to a dedicated EFS Access Point (its own root
  directory, enforced POSIX UID/GID and permission mask) — no path traversal into another
  persona's directory.
- Credentials (LLM API keys, GitHub App PATs) are scoped by path per agent in AWS Secrets
  Manager; each task role can only retrieve its own path.

See [technical-architecture.md](technical-architecture.md) for the full technical design and
[architectual-decisions-record.md](architectual-decisions-record.md) for the reasoning behind
these choices.
