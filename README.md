# Agentic Team (with Paperclip)

Configuration and design for an agentic software-engineering team — a fleet of AI coding agents
coordinated by an orchestration/collaboration layer — that runs either locally or in AWS.

## Start here
- [INTENT.md](INTENT.md) — why this project exists and what it's aiming at.
- [AGENTS.md](AGENTS.md) — rules for agents (and contributors) working in this repo, including
  how documentation is kept current.
- [documentation/](documentation/) — the living product and technical documentation:
  - [product-summary.md](documentation/product-summary.md)
  - [product-details.md](documentation/product-details.md)
  - [technical-architecture.md](documentation/technical-architecture.md)
  - [architectual-decisions-record.md](documentation/architectual-decisions-record.md)
- [configuration-docs/](configuration-docs/) — how a swarm owner configures and deploys the
  platform (e.g. [credentials-and-secrets.md](configuration-docs/credentials-and-secrets.md)).
- [user-docs/](user-docs/) — how a developer uses the deployed agent fleet day to day.
- [specs/260927-agentic-team-w-paperclip/](specs/260927-agentic-team-w-paperclip/) — the active
  feature spec (and source PRD) for the first build of this platform.
- [initial-context.md](initial-context.md) — the original AWS architecture draft this project
  started from. Frozen; superseded by `documentation/technical-architecture.md` where they differ.

## Status
In active development — see the spec above for current scope. No build, lint, or test tooling
exists in the repo yet.
