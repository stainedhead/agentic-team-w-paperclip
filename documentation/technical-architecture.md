# Technical Architecture

> This is the living, authoritative architecture description for this project.
> `../initial-context.md` is the frozen originating draft — where the two differ, this file wins.

## Status
The design below covers the AWS-hosted deployment only. It's a design draft, not yet built.
Local-mode architecture is undesigned (see "Open questions" below and [INTENT.md](../INTENT.md)).

## 1. Platform layers
- **Orchestration & Collaboration Plane**: a centralized Paperclip AI instance (ECS Fargate)
  managing org structure, agent heartbeats, project graphs, budgets, and developer collaboration.
  Runs the Paperclip AI Core Engine plus embedded Hermes & OpenCode CLI tooling. State store:
  Aurora Serverless v2 (PostgreSQL). Persistent files: EFS Access Point at
  `/orchestration/paperclip`.
- **Worker Fleet**: dedicated, long-running ECS Fargate tasks, one per agent persona (e.g.
  Security Auditor, Database Architect, QA Automation), each with its own task role, EFS access
  point, and secrets path.

## 2. Request flow
```
[ Developers / Browser / CLI ]
              │
              ▼
[ Ingress & Authentication ]
  - ALB (Okta OIDC Native Flow)
  - API Gateway (Okta JWT Authorizer)
              │
              ▼ (Private Subnet)
[ Paperclip Orchestrator Service (ECS Fargate) ]
              │
   AWS Cloud Map Private DNS
              │
   ┌──────────┼──────────┐
   ▼          ▼          ▼
[Worker:   [Worker:   [Worker:
 Security]  DB Arch]   QA Test]
```

## 3. Compute
- **Worker agents**: distinct long-running ECS services built from a single standardized base
  container image (runtime toolchain: Hermes, OMP, OpenCode CLI, Git, language SDKs). Fargate on
  Linux ARM64 (Graviton). Per task: 4 vCPU / 8 GB RAM / 50 GB ephemeral NVMe storage.
  - Ephemeral root: git checkouts, compilation output, AST caches, temp build scripts.
  - Persistent memory (EFS): bound to `~/.hermes/`, holds agent skills (`SKILL.md`), vector DBs,
    and long-term memory across restarts.
- **Orchestration task** (Paperclip AI): same compute profile (4 vCPU / 8 GB / 50 GB ephemeral).
  State: Aurora Serverless v2 (task graph, budget caps, execution locks, event logs). Artifacts:
  EFS Access Point at `/home/agent/.paperclip`.
- **Deployment pattern**: "Model 3: CDK Factory Pattern" — a single base image, workers built from
  it as distinct ECS services via a CDK factory.

## 4. Identity, security & isolation
- **IAM task role boundaries**: every worker runs under its own IAM role, scoping its blast
  radius to its assigned permissions.
- **Filesystem confinement**: one shared EFS filesystem, accessed exclusively via per-persona EFS
  Access Points — dedicated root directory (e.g. `/agents/security-auditor`), enforced POSIX
  UID/GID 1000:1000, permission mask 0750, no path traversal into sibling directories.
- **Credential isolation**: AWS Secrets Manager credentials scoped by path
  (`/agents/${AGENT_ID}/*`); IAM policy only allows retrieval of the matching path.
- **Ingress/Okta integration**: Paperclip has no native SSO. Identity is enforced at the AWS
  ingress boundary instead:
  - Browser access: internet-facing ALB with a native Okta OIDC "Authenticate" action; injects
    verified claims (`x-amzn-oidc-identity`, `x-amzn-oidc-data`) upstream.
  - Programmatic/API access: API Gateway (HTTP API) with an Okta JWT Authorizer, validated
    against Okta's JWKS, routed into the VPC via a VPC Link.

## 5. Inter-service communication
- Internal service discovery via AWS Cloud Map (`.agentic.local` private DNS).
- Worker tasks accept inbound traffic only from the Paperclip security group.
- Human-agent collaboration: developers use the Paperclip dashboard (Okta SSO) to review
  worktrees, budgets/token burn, assign issues, and invoke personas via `@agent-name`; Paperclip
  dispatches over private DNS and orchestrates downstream review loops between workers.

## 6. Cost model
Baseline per worker (4 vCPU / 8 GB / 50 GB ephemeral, Graviton, us-east-1, 730 hr/month):
~$117.77/month running 24/7, ~$31.45/month running business-hours-only. Shared infra (NAT
Gateway, Aurora Serverless v2, ALB, EFS Elastic IOPS) is amortized across the fleet. See
`../initial-context.md` §6 for the line-item breakdown.

## Open questions
- **Local-mode architecture**: undesigned. No source material yet describes what running
  "locally" means for this platform, or what (if anything) is shared with the AWS design above.
