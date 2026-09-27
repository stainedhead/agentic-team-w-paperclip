# AGENTS.md

Rules and context for agents (and contributors) working in this repository.

## Project
This repository provides the **baseline containerized tooling and documentation** a swarm owner
builds an agentic teammate group from: two container images carrying Hermes, OMP, OpenCode CLI and
(in one variant) Paperclip, plus the configuration templates and docs around them.

**Scope boundary — keep this in mind for every change.** This project packages and configures
existing tools. It does not implement harnesses or orchestrators, does not deploy anything, and does
not configure a specific team. Those belong to the upstream projects and to the swarm owner
respectively. See [INTENT.md](INTENT.md) for why and ADR-0010 for the decision; `documentation/` for
what and how.

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
- `images/harness/`, `images/paperclip/` — the two container images: Dockerfiles, entrypoints, the
  shared `harness-bootstrap.sh`, and the default `instance.yaml` template. Each image's **build
  context is its own directory**, not the repo root (ADR-0012).
- `.github/workflows/build-and-publish.yml` — lint → smoke-build → multi-arch publish to GHCR.
- `configuration-docs/` — how a swarm owner configures and deploys the platform (credentials,
  Paperclip agent registration, per-target deployment, building custom images).
- `user-docs/` — how a developer uses the deployed agent fleet day to day.
- `templates/` — copy-pasteable artifacts for swarm owners: `.env` examples, `instance.yaml`
  examples, an ECS task definition, EKS manifests, a macOS run script. **Never commit a filled-in
  credential here** — only `*.example` files and `REPLACE-…`/`<placeholder>` values.
- `specs/YYMMDD-<feature-name>/` — an active feature spec, following the dev-flow progressive
  documentation workflow (`spec.md`, `status.md`, `research.md`, etc.); the source PRD for that
  feature lives inside its spec directory once `/create-spec` has run, not at repo root.
  `specs/archive/` holds completed specs.

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
| New/changed requirement before it's built | the active spec's PRD, or a new `*-PRD.md` at repo root if no spec exists yet for it |
| How a swarm owner configures/deploys the platform | `configuration-docs/` |
| How a developer uses the deployed fleet | `user-docs/` |
| A new/changed `instance.yaml` field | `images/harness/instance.default.yaml`, `user-docs/configuration-reference.md`, and `templates/instance/` |
| A new or changed copy-pasteable artifact | `templates/` (plus the deploy doc that references it) |
| Anything a newcomer needs to get oriented | `README.md` |

Two rules that apply to all of the above:

- **User-facing docs must not link into `specs/` or `specs/archive/`.** Archived spec internals are
  process records, not documentation — lift the content into `configuration-docs/`, `user-docs/` or an
  ADR instead, and link there.
- **Don't cite `FR-NNN` requirement numbers in user-facing docs.** They mean nothing without the spec
  archive open alongside. Describe the behavior; cite ADRs where a *decision* needs justifying.

## Current state
The repo builds two container images and publishes them to GHCR. There is no application source
tree and no unit-test suite — the "code" is Dockerfiles, shell entrypoints, and CI.

**Verification toolchain**, all via `.github/workflows/build-and-publish.yml`:
- `shellcheck` on every shell script, `hadolint` on both Dockerfiles.
- A `smoke-build` job that builds both images single-arch, runs them, and asserts uid 1000, every tool
  on `PATH` after the privilege drop, and a working `instance.yaml` bootstrap.

Locally: `bash -n` on the scripts, and `docker build images/harness` (note the context — ADR-0012).
The bootstrap can be exercised without starting Hermes by sourcing it:
`docker run --rm -it --entrypoint /bin/bash <image>` then
`source /opt/agentic-team/harness-bootstrap.sh`.

**Nothing has been confirmed against a real Docker daemon yet.** Prefer changes that CI's smoke-build
job can verify over changes that only static reading can justify, and say plainly in docs what remains
unverified rather than implying it works.

The infrastructure draft (`initial-context.md`) specifies AWS CDK ("Model 3: CDK Factory Pattern") as
the intended IaC approach for the target design in `technical-architecture.md` sections 1-6; that
design is not built and that tooling is not present (ADR-0010).
