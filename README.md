# Agentic Team (with Paperclip)

A fleet of AI agent personas (CTO, Architect, TechLead, Reviewer, Intern, DevSupport, Researcher,
Librarian), coordinated by Paperclip, packaged as two container images a swarm owner deploys
locally (macOS `Container`) or in AWS (ECS Fargate, EKS).

## Get started
- [user-docs/](user-docs/) — getting started, configuration reference, and usage examples for
  running your own harness/Paperclip instances.
- [configuration-docs/](configuration-docs/) — credentials/secrets, GitHub CLI/PAT setup, and
  per-target deployment examples.
- [images/](images/) — the Dockerfiles this product builds and publishes to GHCR
  (`ghcr.io/stainedhead/agentic-team-w-paperclip/harness` and `.../paperclip`) via
  [`.github/workflows/build-and-publish.yml`](.github/workflows/build-and-publish.yml).

## Project context
- [INTENT.md](INTENT.md) — why this project exists and what it's aiming at.
- [AGENTS.md](AGENTS.md) — rules for agents (and contributors) working in this repo, including
  how documentation is kept current.
- [documentation/](documentation/) — the living product and technical documentation:
  - [product-summary.md](documentation/product-summary.md)
  - [product-details.md](documentation/product-details.md)
  - [technical-architecture.md](documentation/technical-architecture.md)
  - [architectual-decisions-record.md](documentation/architectual-decisions-record.md)
- [specs/archive/](specs/archive/) — completed feature specs (and their source PRDs), most
  recently [260927-agentic-team-w-paperclip/](specs/archive/260927-agentic-team-w-paperclip/)
  (the first build) and
  [260927-agentic-team-w-paperclip-auto-review/](specs/archive/260927-agentic-team-w-paperclip-auto-review/)
  (its code-review fix pass). No spec is currently active.
- [initial-context.md](initial-context.md) — the original AWS architecture draft this project
  started from. Frozen; superseded by `documentation/technical-architecture.md` where they differ.

## Status
Both container images build (Dockerfiles, entrypoints) and CI/CD (build, multi-arch, publish to
GHCR, lint, release) are implemented, including fixes from a code-review pass — see
[DEV-FLOW-STATUS.md](DEV-FLOW-STATUS.md) for the full build history. **Not yet verified with a
real `docker build`/`docker run`** — no Docker daemon was available in the environment this was
built in, so all fixes were checked via static analysis (bash reproduction, manual trace-through,
syntax checks) rather than an actual build. That real build/run pass is the next thing this
project needs before the images can be trusted.
