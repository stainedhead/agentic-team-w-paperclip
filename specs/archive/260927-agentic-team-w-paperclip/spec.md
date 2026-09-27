# Spec: Agentic Team with Paperclip

**Created:** 2026-09-27
**Status:** Draft

## Executive Summary

This feature delivers the buildable artifacts for an agentic software-engineering platform: two
container image variants (a harness-only image running Hermes/OMP/OpenCode CLI, and a
harness-plus-Paperclip image built from it), the configuration/documentation needed for a swarm
owner to run them locally (macOS `Container`) or in AWS (ECS Fargate, EKS), and the CI/CD that
builds and publishes those images to GHCR and cuts GitHub Releases. The product does not perform
deployment itself — that is the swarm owner's responsibility once they have the images and docs.

## Problem Statement

Development teams need a way to delegate engineering work to a coordinated team of specialized
AI agents — with defined roles (CTO, Architect, TechLead, Reviewer, Intern, DevSupport,
Researcher, Librarian) — that can operate either in a local lab environment or a cloud
deployment, without each team building bespoke agent infrastructure, model-host integrations, and
work-assignment plumbing from scratch.

## Goals / Non-Goals

### Goals
- **G1:** Enable a team of agents — via an orchestration layer or CLI harnesses — to collaborate
  on work in either a local lab environment or a cloud deployment environment.
- **G2:** Support pluggable model hosts (AWS Bedrock, Ollama Cloud, OpenRouter, Anthropic,
  OpenAI), configurable per harness.
- **G3:** Give harnesses persistent identity across restarts/redeployments.
- **G4:** Let Paperclip source work from multiple systems (its own native work items, Jira,
  GitHub Projects) and let harnesses retrieve their assignments by polling Paperclip.

### Non-Goals
- Real-time monitoring of agent internals.
- Billing/chargeback system (for now).
- Automating deployment into a swarm owner's runtime environment. This product delivers the
  container images, documentation, and CI/CD to build and publish them; actually deploying to a
  local lab (macOS `Container`), ECS Fargate, or EKS is the swarm owner's responsibility.

## User Requirements

### Functional Requirements

**FR-001:** The system shall support defining a set of agent personas: CTO, Architect, TechLead,
Reviewer, Intern, DevSupport, Researcher, Librarian.

**FR-002:** A harness instance shall be configurable to support one or more personas
simultaneously, as designed and configured by the swarm owner (the human operating the system).

**FR-003:** The system shall support three harness types — Hermes, OMP, and OpenCode CLI — each
installable on any swarm machine.

**FR-004:** Hermes shall run as the default, always-on harness on each machine, and shall be
capable of orchestrating OpenCode CLI and/or OMP CLI as subordinate/background instances it
invokes behind the scenes.

**FR-005:** The system shall provide documentation for configuring which harness(es) run on a
given machine; harness selection per machine is a swarm-owner design decision, and not every
machine runs every harness.

**FR-006:** Local lab deployment shall run harness instances as containers using the native
macOS `Container` runtime.

**FR-007:** Cloud deployment shall support running harness instances as ECS Fargate tasks.

**FR-008:** Cloud deployment shall also support EKS, configurable to a target AWS Account,
Cluster, and Namespace.

**FR-009:** The system shall allow each harness instance to be configured with one or more model
hosts — AWS Bedrock, Ollama Cloud, OpenRouter, Anthropic, OpenAI — including whatever
credentials/config that host requires.

**FR-010:** A harness instance's persistent identity shall include both (a) an authentication
identity (credentials/account distinct per persona — e.g. a dedicated GitHub bot account, API
credentials) and (b) persisted memory/skills state that survives restarts.

**FR-011:** Paperclip shall maintain a roster of registered agents — each entry pairing a harness
instance's identity with its persona/role — and shall track available work drawn from configured
external assignment sources (Jira, GitHub Projects) as well as its own native work items.

**FR-012:** Agents shall communicate progress and collaborate with one another through Paperclip.

**FR-013:** Agents shall be able to query external systems (Jira, GitHub Projects) directly to
retrieve additional detail/context on an assigned work item.

**FR-014:** Agents shall be able to update external systems directly as part of completing work
(e.g., closing a Jira ticket).

**FR-015:** Regardless of any external-system updates, agents shall also update Paperclip's
centralized work-tracking state — Paperclip is the system of record for work status across all
sources.

**FR-016:** The system shall build two container image variants: (a) a harness-only image
containing Hermes, OMP, and OpenCode CLI, which runs Hermes on startup; and (b) a
harness-plus-Paperclip image, built `FROM` the harness-only image as its base layer, adding
Paperclip and running both Hermes and Paperclip on startup. Building the Paperclip image from the
harness-only image keeps harness-layer changes in sync across both variants.

**FR-017:** The swarm owner shall configure each harness instance directly with the persona(s),
identity/credentials, and metadata that instance is to run.

**FR-018:** The swarm owner shall separately register each harness instance's agent identity and
persona/role with Paperclip, so Paperclip's roster is aware of that agent and its role.

**FR-019:** Each harness instance shall poll Paperclip on a recurring schedule — using the
harness's built-in cron/scheduling capability — to retrieve any work assigned to its registered
persona/role.

**FR-020:** Joining the swarm shall require only: (1) registering the agent's identity and
persona/role in Paperclip (FR-018), and (2) starting the harness container with its local
configuration (FR-017) — after which polling (FR-019) begins automatically with no further steps.

**FR-021:** The Hermes polling cron schedule shall have a sensible default interval, so a swarm
owner is not required to configure it explicitly to get baseline polling behavior.

**FR-022:** Leaving the swarm shall be accomplished by stopping the harness container; Paperclip
shall treat an agent's roster entry as stale/inactive once it misses its expected poll interval,
rather than requiring an explicit deregistration step.

**FR-023:** Updating a harness instance shall be accomplished by redeploying a new container
image (per FR-016's image variants), rather than in-place mutation of a running instance.

**FR-024:** Each container instance (harness-only or harness+Paperclip) shall be provisioned
with persistent storage that survives container restarts and image updates.

**FR-025:** On startup, if no existing configuration/metadata is found on persistent storage, the
instance shall write out default configuration and metadata.

**FR-026:** On an update (redeploying a new image per FR-023), the instance shall reuse the
existing configuration/metadata/state found on persistent storage rather than regenerating
defaults.

**FR-027:** In local deployments, credentials/secrets shall be sourced from a `.env` file
provided to the container; the default configuration/metadata bootstrap (FR-025) shall never
write credential values into persistent storage itself.

**FR-028:** In AWS deployments, credentials/secrets shall be sourced from AWS Secrets Manager,
with the instance's configuration set to reference the appropriate secret rather than embedding
credential values.

**FR-029:** Documentation shall be provided for configuring credentials/secrets in both modes —
the local `.env` approach and the AWS Secrets Manager approach — under `configuration-docs/`.

**FR-030:** CI/CD shall build both container image variants (FR-016) and publish them to GHCR
(GitHub Container Registry).

**FR-031:** CI/CD shall support cutting GitHub Releases for the product.

**FR-032:** The product shall provide deployment examples/documentation for each supported
target (macOS `Container`, ECS Fargate, EKS), but shall not itself automate deployment into a
swarm owner's environment — that step is performed by the swarm owner.

**FR-033:** Documentation shall be provided for configuring GitHub CLI (`gh`) authentication
(Personal Access Token) for a harness instance. This is the actual configuration surface for
GitHub interaction (Projects and/or Issues) regardless of whether it's exercised through
Paperclip's own GitHub connector or an agent's direct use of `gh` — this product documents the
credential setup, not a specific GitHub Projects/Issues integration mechanism (see the note under
FR-013/FR-014 in "Scope note: GitHub integration mechanism" below).

#### Scope note: GitHub integration mechanism (FR-011, FR-013, FR-014, FR-033)

Research into Paperclip's real GitHub connector found it syncs **GitHub Issues** (single-repo)
via a documented comment/@mention flow; no documentation was found for a GitHub **Projects**
(cross-repo board) integration specifically. The product intent is still GitHub Projects, since
it isn't scoped to a single repo the way Issues is — but this spec does not commit to *how*
Paperclip or an agent accesses Projects internally (native connector vs. an agent shelling out to
`gh` directly). This product's deliverable is narrower and concrete: document `gh` CLI + PAT
configuration (FR-033) so that whichever mechanism ends up being used has working
authentication. Whether Paperclip's own roadmap adds native Projects support is out of scope and
untracked here.

### Non-Functional Requirements

- **Observability:** Supported on all deployment platforms (macOS `Container`, ECS Fargate,
  EKS). Logging level is configurable at the instance level, defaulting to "normal" verbosity.
- **Security:** Credentials/secrets are never written into the product's default-bootstrap
  configuration (FR-025). Locally they are sourced from a `.env` file (FR-027); in AWS they are
  sourced from AWS Secrets Manager (FR-028). Beyond this boundary, general security posture is
  the swarm owner's responsibility at deployment/configuration time.
- **Performance / Reliability:** Not prescribed by this product directly. The product's
  responsibility is to ship preconfigured containers/images that expose the necessary
  configuration surface; the swarm owner sets the actual performance and reliability posture at
  deployment/configuration time for their environment.

## System Architecture

Concrete tool identities confirmed by research (2026-09-27) — see `research.md` and the
Dependencies table below for sourcing:
- **Hermes** = Nous Research's Hermes Agent. Installed via its own installer/gateway install
  command; YAML config at `~/.hermes/config.yaml`; built-in cron scheduler (jobs at
  `~/.hermes/cron/jobs.json`) satisfies FR-004/FR-019/FR-021; invokes OpenCode CLI/OMP generically
  via its shell/subprocess tool access (no named integration — a cron job's prompt/script just
  shells out).
- **OMP** = oh-my-pi. YAML config (global `~/.omp/agent/config.yml`, project-local
  `.omp/config.yml`); non-interactive invocation via `omp -p "..."`.
- **OpenCode CLI** — install via curl/npm/pnpm/bun/brew; config via `OPENCODE_CONFIG*` env vars;
  non-interactive invocation via `opencode run "..."`, or `opencode serve` + `opencode run
  --attach` for repeated calls without cold-start cost.
- **Paperclip** — agent registration (FR-018) via `paperclipai agent create`/`agent hire` CLI
  (or its UI); work retrieval (FR-019) via `paperclipai agent inbox`/`inbox-mine` CLI, called from
  a Hermes cron job; auth via a long-lived Agent API key (Bearer token).

Known constraints:
- Two image variants, with the Paperclip image built `FROM` the harness-only image (FR-016).
- CI/CD publishes both images to GHCR and supports GitHub Releases (FR-030/FR-031), using the
  standard `docker/build-push-action` + `GITHUB_TOKEN` pattern.
- No traditional business-logic "domain" layer is implied by this PRD — the deliverable is
  Dockerfiles installing existing tools, CI/CD, and documentation, not an application with
  persistent runtime business logic built by this repo. Tool-internal behavior (retries, cron
  internals, credential-failure handling) is each tool's own concern — see "Edge Case Handling"
  below.
- Remaining architecture decision, not yet made: how the harness-instance's *own* configuration
  (persona assignment, model-host selection — FR-017) is represented as a file, and where it's
  read by which tool. This is genuinely new (not covered by any of the four tools' own config
  formats) and is the one piece of "architecture" this spec still owes before implementation.

## Edge Case Handling (Scope Boundary)

Hermes, OMP, OpenCode CLI, and Paperclip are existing, mature tools — this product configures
and containerizes them; it does not reimplement or override their runtime behavior. Accordingly,
the following classes of failure/edge-case are explicitly **out of scope** for this spec, and are
owned by the respective tool (see its own documentation, referenced from
`configuration-docs/` and `user-docs/` once written, rather than re-specified here):

- Poll-failure retry/backoff behavior when a harness can't reach Paperclip.
- How Paperclip handles a duplicate agent-identity registration.
- How a harness or Paperclip behaves when a model-host or external-system (Jira/GitHub) credential
  is invalid or expired at runtime.
- Detection/recovery of corrupted or partially-written state in a tool's own persisted data.

What **is** in scope for this product: making sure persistent storage (FR-024) is mounted where
each tool expects it, credentials are supplied to each tool the way it expects to receive them
(`.env` locally, AWS Secrets Manager in AWS — FR-027/FR-028), and default-config bootstrap
(FR-025/FR-026) only concerns configuration this product itself introduces (e.g. persona
assignment, model-host selection) — not a tool's own internal state format, which the tool
manages itself.

## Scope of Changes

- New: `images/harness/Dockerfile` — installs Hermes (Nous Research Hermes Agent), OMP (oh-my-pi),
  and OpenCode CLI; entrypoint runs Hermes.
- New: `images/paperclip/Dockerfile` — `FROM` the harness image (FR-016); adds Paperclip;
  entrypoint runs both Hermes and Paperclip.
- New: `images/harness/entrypoint.sh` (and `images/paperclip/entrypoint.sh` if it needs its own) —
  handles the default-config bootstrap-vs-reuse behavior (FR-025/FR-026) against the mounted
  persistent-storage volume.
- New: `.github/workflows/build-and-publish.yml` — builds both images, publishes to GHCR
  (FR-030), triggers on push/tag; a release job cuts a GitHub Release (FR-031).
- New/updated: `configuration-docs/credentials-and-secrets.md` (already exists — extend with
  concrete env var / Secrets Manager path names once the instance config schema is decided).
- New: `configuration-docs/github-cli-and-pat.md` — `gh` CLI + PAT setup (FR-033).
- New: `configuration-docs/` deployment examples — one per target (macOS `Container`, ECS
  Fargate, EKS) per FR-032, including the macOS `Container` persistent-storage recipe (PRD's
  narrowed open question).
- New: `user-docs/` guides (currently only a placeholder README exists) — getting-started,
  configuration reference, usage examples, per Step 4 of the implementation pipeline.
- Updated: `documentation/technical-architecture.md` and
  `documentation/architectual-decisions-record.md` — FR-016's base-image-layering decision is
  already flagged as ADR-worthy but not yet recorded; record it once this spec's architecture is
  final.
- Still undecided (blocks finalizing the file list above): the format of the harness instance's
  own configuration file (persona assignment, model-host selection — FR-017) and exactly where in
  the container filesystem it lives relative to Hermes/OMP/OpenCode's own config paths.

## Breaking Changes

None — this is a net-new build; no existing shipped artifact is being changed.

## Success Criteria and Acceptance Criteria

- [ ] Personas (CTO, Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian)
      can be defined and assigned to a harness instance via configuration.
- [ ] A harness instance can be configured to support one or more personas simultaneously.
- [ ] Hermes, OMP, and OpenCode CLI can each be installed and run as a harness on a swarm machine.
- [ ] Hermes runs as the default always-on harness and can invoke OpenCode CLI and/or OMP CLI as
      subordinate processes behind the scenes.
- [ ] Documentation exists describing how to configure which harness(es) run on a given machine,
      since not all machines run all harnesses.
- [ ] Local lab deployment runs a harness instance as a container under the native macOS
      `Container` runtime.
- [ ] AWS deployment runs a harness instance as an ECS Fargate task.
- [ ] AWS deployment can alternatively run a harness instance on EKS, targeting a configurable
      Account, Cluster, and Namespace.
- [ ] A harness instance can be configured against any of: AWS Bedrock, Ollama Cloud, OpenRouter,
      Anthropic, or OpenAI as its model host, including required credentials.
- [ ] A harness instance retains persistent identity — both its authentication identity and its
      persisted memory/skills state — across a restart.
- [ ] Paperclip polls Jira and GitHub Projects for assigned work and maintains a roster of
      registered agents (harness instance identity + persona/role) with their available work.
- [ ] An agent can query Jira or GitHub Projects directly to retrieve additional detail on an
      assigned item.
- [ ] An agent can update an external system (e.g., close a Jira ticket) and Paperclip's
      centralized work-tracking state reflects the same completion.
- [ ] An instance's logging level is configurable locally and defaults to "normal" when unset.
- [ ] Two container image variants exist: a harness-only image (Hermes, OMP, OpenCode CLI;
      Hermes runs on startup) and a harness-plus-Paperclip image built `FROM` the harness-only
      image (both Hermes and Paperclip run on startup).
- [ ] A harness instance can be configured by the swarm owner with persona(s), identity/
      credentials, and metadata, independent of its registration in Paperclip.
- [ ] A harness instance's agent identity and persona/role can be registered in Paperclip's
      roster by the swarm owner, separately from the instance's own local configuration.
- [ ] A harness instance polls Paperclip on a recurring, cron-driven schedule and retrieves any
      work assigned to its registered persona/role.
- [ ] Joining the swarm requires only registering the agent in Paperclip and starting the
      harness container — polling begins automatically with no further manual steps.
- [ ] The Hermes polling cron schedule works out of the box with a sensible default interval.
- [ ] Stopping a harness container removes it from active work assignment once Paperclip's
      stale/missed-poll check trips, without requiring an explicit deregistration step.
- [ ] Updating a harness instance is done by redeploying a new container image, not by mutating
      a running instance in place.
- [ ] A container instance is provisioned with persistent storage that survives restarts and
      image updates.
- [ ] On first start with no existing configuration on persistent storage, the instance writes
      default configuration and metadata.
- [ ] After an image update, the instance reuses existing configuration/metadata/state from
      persistent storage instead of regenerating defaults.
- [ ] In a local deployment, credentials/secrets are sourced from a `.env` file, and the
      default-config bootstrap never writes credential values to persistent storage.
- [ ] In an AWS deployment, credentials/secrets are sourced from AWS Secrets Manager, referenced
      by configuration rather than embedded.
- [ ] `configuration-docs/` contains documentation covering both the local `.env` approach and
      the AWS Secrets Manager approach, and is referenced from `README.md`.
- [ ] CI/CD builds both container image variants and publishes them to GHCR.
- [ ] CI/CD supports cutting a GitHub Release for the product.
- [ ] Deployment examples/documentation exist for macOS `Container`, ECS Fargate, and EKS,
      without the product itself automating deployment into any of them.
- [ ] `configuration-docs/` contains documentation for configuring `gh` CLI authentication (PAT)
      on a harness instance.

### Quality Gates
- [ ] All acceptance criteria above verified.
- [ ] Both image variants build successfully in CI and are pushed to GHCR.
- [ ] A GitHub Release can be cut from CI.
- [ ] `README.md`, `documentation/`, `configuration-docs/`, and `user-docs/` all reflect what was
      actually built (not just what was planned).

## Risks and Mitigation

| Item | Type | Notes |
|------|------|-------|
| Hermes = Nous Research's Hermes Agent ([github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)) | Dependency | Confirmed 2026-09-27 via research: real built-in cron scheduler (60s gateway tick, jobs at `~/.hermes/cron/jobs.json`), YAML config at `~/.hermes/config.yaml`, secrets at `~/.hermes/.env`, generic shell/subprocess tool access (not a named "invoke OpenCode" feature — it shells out like any other tool call). |
| OMP = oh-my-pi ([omp.sh](https://omp.sh/docs/cli), [github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)) | Dependency | Confirmed 2026-09-27: terminal coding agent, 60+ model providers, YAML config (global `~/.omp/agent/config.yml`, project-local `.omp/config.yml`), non-interactive via `-p`/`--print`. Install method not confirmed from docs fetched — verify directly before writing the Dockerfile. |
| OpenCode CLI ([opencode.ai/docs/cli](https://opencode.ai/docs/cli/)) | Dependency | Confirmed 2026-09-27: install via curl/npm/pnpm/bun/brew, config via `OPENCODE_CONFIG`/`OPENCODE_CONFIG_DIR`/`OPENCODE_CONFIG_CONTENT` env vars, auth at `~/.local/share/opencode/auth.json`. Non-interactive via `opencode run` (one-shot) or `opencode serve` + `opencode run --attach` (headless HTTP API, avoids cold starts). |
| Paperclip ([paperclip.ing](https://paperclip.ing/), [docs.paperclip.ing](https://docs.paperclip.ing/reference/api/overview/), [github.com/paperclipai/paperclip](https://github.com/paperclipai/paperclip)) | Dependency | Confirmed 2026-09-27: agent registration via CLI (`paperclipai agent create`/`agent hire`) or UI, not just config; work retrieval via `paperclipai agent inbox`/`inbox-mine` CLI (pull) or a server-side wakeup API (push) — FR-019's harness-cron-polls-Paperclip design uses the pull side. Auth: Agent API keys (Bearer), run JWTs, or session cookies. |
| Jira API | Dependency | Paperclip's real Jira connector is OAuth, Atlassian Cloud only, covers Jira issues + Confluence (not Data Center/Server). Used for querying assigned work, fetching detail, and closing tickets. |
| GitHub (Projects intent; connector confirmed for Issues only) | Dependency | See spec's "Scope note: GitHub integration mechanism" above — Paperclip's documented GitHub connector syncs Issues (single-repo), not Projects; this product's deliverable is `gh` CLI + PAT configuration docs (FR-033), not a specific connector integration. |
| AWS Bedrock | Dependency | One of five configurable model hosts. |
| Ollama Cloud | Dependency | One of five configurable model hosts. |
| OpenRouter | Dependency | One of five configurable model hosts. |
| Anthropic API | Dependency | One of five configurable model hosts. |
| OpenAI API | Dependency | One of five configurable model hosts. |
| macOS `Container` runtime | Dependency | Native container runtime for local lab deployment. |
| AWS ECS Fargate | Dependency | Cloud deployment target (see `documentation/technical-architecture.md`). |
| AWS EKS | Dependency | Alternate cloud deployment target; configurable Account/Cluster/Namespace. |
| AWS Secrets Manager | Dependency | Source of credentials/secrets for AWS deployments (FR-028). |
| GHCR (GitHub Container Registry) | Dependency | Publish target for both container image variants (FR-030). Standard `docker/build-push-action` + `GITHUB_TOKEN` (packages: write) pattern confirmed current as of 2026-09-27. |
| GitHub Releases | Dependency | Release mechanism for the product (FR-031). |
| Local-mode architecture undesigned | Risk | Narrowed by scope: this product only owes a documented persistent-storage recipe for the macOS `Container` example (see Open Questions); full local networking/service-discovery/identity-store design is the swarm owner's concern. |
| Credential sprawl | Risk | Each harness instance may hold credentials for a model host, an auth identity, a Paperclip Agent API key, a Jira OAuth grant, and a GitHub PAT — increases surface area for credential management/rotation. |
| OMP install method unverified | Risk | omp.sh's CLI reference page didn't document the install method directly (only `omp update` for upgrades) — confirm the actual install command before writing its Dockerfile step. |
| Paperclip GitHub Projects support unconfirmed | Risk | Paperclip's documented GitHub connector covers Issues; no documented Projects-specific sync was found. Mitigated by narrowing this product's deliverable to `gh` CLI/PAT configuration (FR-033) rather than a specific connector guarantee. |

## Timeline and Milestones

`[TBD — to be set during plan.md/tasks.md breakdown.]`

## References

- Source PRD: `specs/260927-agentic-team-w-paperclip/agentic-team-w-paperclip-PRD.md`
- `documentation/technical-architecture.md` — AWS architecture this spec's AWS deployment
  examples must stay consistent with.
- `documentation/architectual-decisions-record.md` — existing ADR log; FR-016's base-image
  layering decision is flagged there as ADR-worthy but not yet recorded.
- `configuration-docs/credentials-and-secrets.md` — existing credentials documentation this spec
  extends (FR-027/FR-028/FR-029).
- `INTENT.md` — original intent, including the now-narrowed local-mode open question.
