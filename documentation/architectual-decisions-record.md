# Architectural Decision Record

Append-only log. To change a decision, add a new entry that supersedes the old one — never edit
a past entry in place.

## ADR-0001: Deploy the worker fleet as long-running ECS Fargate tasks on ARM64 (Graviton)
- **Status**: Accepted (2026-09-27)
- **Context**: Need isolated, long-running compute per agent persona.
- **Decision**: Each agent persona runs as a distinct long-running ECS Fargate service, built
  from a common base container image, on Linux ARM64 (Graviton).
- **Consequences**: Lower cost profile than x86; requires ARM64-compatible toolchain images.

## ADR-0002: Isolate personas by IAM task role + EFS Access Point, not shared credentials/filesystem
- **Status**: Accepted (2026-09-27)
- **Context**: Agents execute arbitrary code (e.g. during testing) against real infrastructure; a
  compromised or misbehaving agent should have a bounded blast radius.
- **Decision**: Every worker task gets its own IAM task role; filesystem access goes through a
  dedicated EFS Access Point per persona (own root directory, enforced POSIX UID/GID 1000:1000,
  permission mask 0750); Secrets Manager credentials are scoped by path per agent.
- **Consequences**: The QA agent cannot reach production data stores; the DB Architect agent
  cannot modify IAM; no path traversal between persona directories.

## ADR-0003: Enforce identity (Okta) at the AWS ingress boundary, not inside Paperclip
- **Status**: Accepted (2026-09-27)
- **Context**: Paperclip AI has no native enterprise SSO / Okta SAML/OIDC handling.
- **Decision**: Offload identity enforcement to the ingress layer — ALB with a native Okta OIDC
  Authenticate action for browser traffic; API Gateway with an Okta JWT Authorizer for
  programmatic traffic. Verified claims are injected upstream to Paperclip.
- **Consequences**: Paperclip trusts the ingress layer's claims rather than performing its own
  auth; ingress configuration becomes security-critical.

## ADR-0004: Use Aurora Serverless v2 (PostgreSQL) as the orchestrator's state store
- **Status**: Accepted (2026-09-27)
- **Context**: The orchestration plane needs a durable store for the task graph, budget caps,
  execution locks, and event logs.
- **Decision**: Back the Paperclip orchestrator with Aurora Serverless v2 (PostgreSQL).
- **Consequences**: Serverless scaling of the state store; cost shared/amortized across the fleet.

## ADR-0005: Build worker deployments with a CDK factory pattern from a single base image
- **Status**: Accepted (2026-09-27)
- **Context**: Multiple worker personas need consistent, repeatable deployment with
  persona-specific isolation config layered on top.
- **Decision**: Use a single standardized base container image (Hermes, OMP, OpenCode CLI, Git,
  language SDKs) and generate each persona's ECS service via a CDK factory ("Model 3").
- **Consequences**: Consistent runtime across personas; persona differences are expressed as
  factory parameters (IAM role, EFS access point, secrets path) rather than divergent images.

## ADR-0006: Build the harness+Paperclip image FROM the harness-only image
- **Status**: Accepted (2026-09-27)
- **Context**: The product ships two container image variants — harness-only (Hermes, OMP,
  OpenCode CLI) and harness+Paperclip. Both need the same harness-layer tooling.
- **Decision**: The harness+Paperclip image's Dockerfile (`images/paperclip/Dockerfile`) uses
  `FROM ${BASE_IMAGE}` with the harness-only image as the default base, adding only Paperclip and
  overriding the entrypoint to run both Hermes and Paperclip.
- **Consequences**: Harness-layer changes (tool versions, `yq`/`gh` install, bootstrap logic)
  propagate to both variants automatically instead of drifting apart across two independently
  maintained Dockerfiles. CI pins the FROM relationship by digest (not a mutable tag) to avoid a
  race between the two builds landing on the registry — see
  `.github/workflows/build-and-publish.yml`.

## ADR-0007: Implement the Paperclip work-poll as a Hermes cron job calling Paperclip's own CLI
- **Status**: Accepted (2026-09-27)
- **Context**: FR-019 requires a harness instance to retrieve its assigned work by polling
  Paperclip on a recurring schedule. Paperclip's own platform actually supports two mechanisms:
  a server-initiated heartbeat "wakeup" API, and a pull-style CLI (`agent inbox`/`inbox-mine`).
- **Decision**: Use Hermes's built-in cron scheduler to run `paperclipai agent inbox-mine
  --user-id <id> --status todo,in_progress` on a recurring schedule (default every 5 minutes),
  rather than building custom polling code or wiring up Paperclip's push-based wakeup API.
- **Consequences**: No custom scheduler/poll logic to build or maintain — the mechanism is
  entirely "configure two existing tools to call each other." Retry/failure behavior on a missed
  poll is Hermes's/Paperclip's own concern (see `spec.md`'s Edge Case Handling scope boundary),
  not something this product implements.

## ADR-0008: A single `instance.yaml` file is this product's own configuration surface
- **Status**: Accepted (2026-09-27)
- **Context**: FR-017 requires a swarm owner to configure persona assignment, model-host
  selection, and identity references per harness instance. None of Hermes, OMP, OpenCode CLI, or
  Paperclip has a config format for this — it's specific to this product.
- **Decision**: Introduce `/data/instance.yaml` (on the same persistent-storage volume as
  FR-024) as the single file for this product's own settings, with `*_ref` fields naming (never
  containing) credentials. The entrypoint bootstrap applies its values into each tool's own
  config on startup, rather than duplicating each tool's full native config surface.
- **Consequences**: One clear place a swarm owner edits for this product's own settings; a
  slightly more complex entrypoint (translates `instance.yaml` into Hermes/OMP/OpenCode's native
  config on every start) in exchange for not inventing a broader configuration system.

## ADR-0009: Extend ADR-0002's per-agent Secrets Manager path scheme to all newly-identified credentials
- **Status**: Accepted (2026-09-27)
- **Context**: This product's credential set grew beyond ADR-0002's original scope (model-host
  API keys, a Paperclip Agent API key, a GitHub PAT).
- **Decision**: Reuse ADR-0002's `/agents/${AGENT_ID}/*` path convention for all of them (e.g.
  `/agents/${AGENT_ID}/model-host-api-key`, `/agents/${AGENT_ID}/paperclip-agent-api-key`,
  `/agents/${AGENT_ID}/github-pat`) rather than inventing a separate scheme per credential type.
- **Consequences**: One consistent convention across the whole credential set; a swarm owner who
  wants a shared (non-per-agent) credential, such as one model-host key across agents, deviates
  from this default deliberately rather than the product forcing per-agent secrets everywhere.

## Open (not decided)
- Paperclip's own install/self-host method — see
  [../specs/archive/260927-agentic-team-w-paperclip/research.md](../specs/archive/260927-agentic-team-w-paperclip/research.md).
- Full local networking/service-discovery/identity-store design equivalent to the AWS
  architecture above — narrowed out of scope for this product (the swarm owner's concern for
  their own local environment); see [INTENT.md](../INTENT.md).
