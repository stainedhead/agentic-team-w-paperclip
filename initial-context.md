Architecture Design Document: Enterprise Agentic Engineering Platform
1. Executive Summary
This document specifies the technical architecture for an internal, multi-agent software engineering platform hosted on AWS. The platform deploys autonomous dev workers running Hermes, OpenCode CLI, and OMP alongside an orchestration and collaboration plane powered by Paperclip AI.

The design provides enterprise-grade isolation, fine-grained access governance via Okta, persistent memory management, and human-in-the-loop developer collaboration.

2. Platform Architecture Overview
The system is organized into two primary layers:

Orchestration & Collaboration Plane: A centralized Paperclip AI instance managing organization structure, agent heartbeats, project graphs, budgets, and developer collaboration.
Worker Fleet: Dedicated, long-running ECS Fargate tasks executing development tasks across segregated agent personas (e.g., Security Auditor, Database Architect, QA Automation).
                      [ Developers / Browser / CLI ]
                                     │
                                     ▼
                      [ Ingress & Authentication ]
                      - ALB (Okta OIDC Native Flow)
                      - API Gateway (Okta JWT Authorizer)
                                     │
                                     ▼ (Private Subnet)
            ┌──────────────────────────────────────────────────┐
            │  Paperclip Orchestrator Service (ECS Fargate)    │
            │  - Paperclip AI Core Engine                      │
            │  - Embedded Hermes & OpenCode CLI Tooling        │
            │  - Aurora Serverless v2 PostgreSQL (State Store) │
            │  - EFS Access Point: /orchestration/paperclip    │
            └────────────────────────┬─────────────────────────┘
                                     │
                         AWS Cloud Map Private DNS
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
┌──────────────────┐        ┌──────────────────┐        ┌──────────────────┐
│ Worker: Security │        │ Worker: DB Arch  │        │ Worker: QA Test  │
├──────────────────┤        ├──────────────────┤        ├──────────────────┤
│ Task Role: Sec   │        │ Task Role: DB    │        │ Task Role: QA    │
│ EFS AP: /sec/    │        │ EFS AP: /db/     │        │ EFS AP: /qa/     │
│ Secrets: /sec/*  │        │ Secrets: /db/*   │        │ Secrets: /qa/*   │
└──────────────────┘        └──────────────────┘        └──────────────────┘
3. Infrastructure & Compute Specifications
3.1 Worker Tasks (Model 3: CDK Factory Pattern)
Worker agents are deployed as distinct long-running ECS Services built from a single, standardized base container image containing the runtime toolchain (Hermes, OMP, OpenCode CLI, Git, language SDKs).

Compute Profile: AWS Fargate on Linux ARM64 (AWS Graviton).
Sizing per Task:
vCPU: 4 vCPU
Memory: 8 GB RAM
Ephemeral Storage: 50 GB NVMe (configured via Fargate Ephemeral Storage)
Storage Allocation:
Ephemeral Root: High-churn Git checkouts, compilation outputs, AST caches, and temporary build scripts live directly on the NVMe scratch disk.
Persistent Memory (Amazon EFS): Bound to ~/.hermes/ to persist agent skills (SKILL.md), vector databases, and long-term memory across restarts.
3.2 Orchestration Task (Paperclip AI)
Compute Profile: AWS Fargate on Linux ARM64 (4 vCPU / 8 GB RAM / 50 GB ephemeral storage).
State Persistence: Backed by Amazon Aurora Serverless v2 (PostgreSQL) for the primary task graph, budget caps, execution locks, and event logs. Persistent files and artifacts are backed by a dedicated EFS Access Point mounted at /home/agent/.paperclip.
4. Identity, Security & Isolation Boundaries
4.1 Fleet Persona Isolation
Each agent persona receives dedicated security boundaries configured through the deployment factory:

IAM Task Role Boundaries: Every worker task runs under its own distinct IAM Role. If an agent executes arbitrary code during testing, its blast radius is strictly confined to its assigned permissions (e.g., the QA agent cannot access production RDS clusters; the Database Architect cannot modify IAM roles).
Filesystem Confinement (EFS Access Points): A single Amazon EFS file system is shared across the fleet, but tasks interface exclusively via EFS Access Points. Each access point enforces:
A dedicated root directory (e.g., /agents/security-auditor).
Enforced POSIX UID/GID (1000:1000) and permission masks (0750).
Containers have no path traversals into sibling agent directories.
Credential Isolation: AWS Secrets Manager credentials (LLM API keys, GitHub App PATs) are scoped by path (/agents/${AGENT_ID}/*). IAM task policies allow retrieval only for the matching path.
4.2 Ingress Authentication & Okta Integration
Paperclip does not provide native enterprise SSO or Okta SAML/OIDC handlers. Identity enforcement is offloaded to the AWS ingress layer:

[ Developer / CLI ] ──► [ AWS Ingress Boundary ] ──► [ Paperclip ECS Service ]
                         ├── ALB (Okta OIDC)           (Pre-authenticated
                         └── API GW (Okta JWT)          Request with Claims)
Browser Access (Developers):
Routed through an internet-facing Application Load Balancer (ALB).
The ALB listener integrates directly with Okta using native Authenticate OIDC actions, challenging unauthenticated sessions, managing OAuth tokens, and injecting verified claims (x-amzn-oidc-identity, x-amzn-oidc-data) upstream.
Programmatic / API Access:
Routed through Amazon API Gateway (HTTP APIs) backed by an Okta JWT Authorizer.
Validates bearer tokens against Okta’s JSON Web Key Set (/.well-known/jwks.json).
Authorized requests route into the private VPC via an AWS VPC Link.
5. Inter-Service Communication & Collaboration
Internal Service Discovery: Tasks communicate privately using AWS Cloud Map (.agentic.local private DNS). Worker tasks accept inbound traffic strictly from the Paperclip security group.
Human-Agent Collaboration Workflow:
Developers log in to the Paperclip web dashboard via Okta SSO.
Developers can review active worktrees, view agent budget and token burn rates, assign new issues, or invoke specific personas via @agent-name.
Paperclip signals the target worker instance over private DNS, dispatching context and orchestrating downstream review loops with other worker agents.
6. Financial Model (Per High-End Worker Unit)
Baseline monthly running costs for a 4 vCPU / 8 GB / 50 GB Ephemeral worker instance on Graviton (us-east-1 standard rates, 730 hours/month):

Component	Basis	Monthly Cost (24/7)	Monthly Cost (Business Hours)
Compute (vCPU)	4 cores @ $0.03238/hr	$94.55	$25.25
Compute (Memory)	8 GB @ $0.00356/hr	$20.79	$5.55
Storage (Ephemeral)	30 GB billable @ $0.000111/hr	$2.43	$0.65
Total Base Compute	—	~$117.77	~$31.45
Supporting shared infrastructure (NAT Gateway, Aurora Serverless v2, ALB, EFS Elastic IOPS) is amortized across the entire fleet.