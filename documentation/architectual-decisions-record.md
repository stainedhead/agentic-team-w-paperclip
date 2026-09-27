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

## Open (not decided)
- Local-mode deployment architecture — not yet designed; see [INTENT.md](../INTENT.md) and
  [technical-architecture.md](technical-architecture.md).
