# PRD: Agentic Team with Paperclip

**Created:** 2026-09-27
**Jira:** N/A
**Status:** Draft

## Problem Statement

Development teams need a way to delegate engineering work to a coordinated team of specialized
AI agents — with defined roles (CTO, Architect, TechLead, Reviewer, Intern, DevSupport,
Researcher, Librarian) — that can operate either in a local lab environment or a cloud
deployment, without each team building bespoke agent infrastructure, model-host integrations, and
work-assignment plumbing from scratch.

## Goals

- **G1:** Enable a team of agents — via an orchestration layer or CLI harnesses — to collaborate
  on work in either a local lab environment or a cloud deployment environment.
- **G2:** Support pluggable model hosts (AWS Bedrock, Ollama Cloud, OpenRouter, Anthropic,
  OpenAI), configurable per harness.
- **G3:** Give harnesses persistent identity across restarts/redeployments.
- **G4:** Let Paperclip source work from multiple systems (its own native work items, Jira,
  GitHub Projects) and let harnesses retrieve their assignments by polling Paperclip.

## Non-Goals

- Real-time monitoring of agent internals.
- Billing/chargeback system (for now).
- Automating deployment into a swarm owner's runtime environment. This product delivers the
  container images, documentation, and CI/CD to build and publish them; actually deploying to a
  local lab (macOS `Container`), ECS Fargate, or EKS is the swarm owner's responsibility.

## Functional Requirements

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

## Non-Functional Requirements

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

## Acceptance Criteria

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

## Dependencies and Risks

| Item | Type | Notes |
|------|------|-------|
| Paperclip (orchestrator) | Dependency | Central coordination plane; monitors assignment sources and tracks assignments, which harnesses retrieve by polling. |
| Jira API | Dependency | Used for polling assigned work, fetching detail, and closing tickets. |
| GitHub Projects API | Dependency | Used for polling assigned work and fetching detail. |
| AWS Bedrock | Dependency | One of five configurable model hosts. |
| Ollama Cloud | Dependency | One of five configurable model hosts. |
| OpenRouter | Dependency | One of five configurable model hosts. |
| Anthropic API | Dependency | One of five configurable model hosts. |
| OpenAI API | Dependency | One of five configurable model hosts. |
| macOS `Container` runtime | Dependency | Native container runtime for local lab deployment. |
| AWS ECS Fargate | Dependency | Cloud deployment target (see `documentation/technical-architecture.md`). |
| AWS EKS | Dependency | Alternate cloud deployment target; configurable Account/Cluster/Namespace. |
| AWS Secrets Manager | Dependency | Source of credentials/secrets for AWS deployments (FR-028). |
| GHCR (GitHub Container Registry) | Dependency | Publish target for both container image variants (FR-030). |
| GitHub Releases | Dependency | Release mechanism for the product (FR-031). |
| Local-mode architecture undesigned | Risk | Carried over from `INTENT.md`; this PRD decides the local container runtime (macOS `Container`) but not the full local architecture (networking, service discovery, identity store, etc.) equivalent to the AWS design. |
| Credential sprawl | Risk | Each harness instance may hold credentials for a model host, an auth identity, and potentially Jira/GitHub — increases surface area for credential management/rotation. |

## Open Questions

- **Local-mode architecture**: this PRD now specifies that containers need persistent storage
  (FR-024) and default-config bootstrap behavior (FR-025/FR-026) generically, but the concrete
  mechanism for the macOS `Container` runtime specifically (e.g. what backs the persistent
  volume), plus local networking/service discovery/identity store — equivalent in depth to the
  AWS design in `documentation/technical-architecture.md` — is not yet designed.
