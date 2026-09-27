# AGENTS.md

Rules and context for agents (and contributors) working in this repository.

## Project
This repository designs and configures an agentic software-engineering team that runs either
locally or in AWS. See [INTENT.md](INTENT.md) for why; `documentation/` for what and how.

## Repository layout
- `README.md` — orientation for humans and agents.
- `INTENT.md` — goals and intent behind the project. Update when direction or scope changes.
- `initial-context.md` — the original architecture draft this project started from. **Frozen —
  do not edit.** It is AWS-only and pre-dates the local-mode requirement.
- `documentation/technical-architecture.md` — the **authoritative, living** architecture
  description. Supersedes `initial-context.md` wherever the two differ.
- `documentation/product-summary.md` — short, pitch-level description of the product.
- `documentation/product-details.md` — fuller description: components, workflows, isolation model.
- `documentation/architectual-decisions-record.md` — append-only architectural decision log (ADRs).
- `configuration-docs/` — how a swarm owner configures and deploys the platform (e.g. credentials/secrets setup).
- `user-docs/` — how a developer uses the deployed agent fleet day to day.
- `*-PRD.md` (e.g. `agentic-team-w-paperclip-PRD.md`) — the current product requirements document(s), at repo root.

## Keeping documentation current
The files above are the primary context agents use to understand this product — keep them
accurate. Route each change to the file(s) it belongs in, and give each fact one home (link to it
from elsewhere rather than restating it):

| Kind of change | Update |
|---|---|
| Infrastructure/architecture change | `technical-architecture.md`, plus a new ADR entry |
| A decision made among alternatives | new ADR entry (append-only — supersede old entries, never edit them in place) |
| Product scope or feature change | `product-details.md` (touch `product-summary.md` only if the elevator pitch itself changes) |
| Goal/direction/scope shift | `INTENT.md` |
| New/changed requirement before it's built | the relevant `*-PRD.md` |
| How a swarm owner configures/deploys the platform | `configuration-docs/` |
| How a developer uses the deployed fleet | `user-docs/` |
| Anything a newcomer needs to get oriented | `README.md` |

## Current state
No build, lint, or test toolchain exists yet — this repo is presently documentation/config only.
The infrastructure draft (`initial-context.md`) specifies AWS CDK ("Model 3: CDK Factory Pattern")
as the intended IaC approach once implementation starts; that tooling is not yet present in the repo.
