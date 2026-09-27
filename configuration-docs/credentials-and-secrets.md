# Configuring Credentials and Secrets

A harness or harness+Paperclip instance needs credentials for its configured model host(s),
its own authentication identity, and (where used) Jira/GitHub Projects access. Per
`agentic-team-w-paperclip-PRD.md` (FR-027/FR-028), how those are sourced depends on the
deployment target — but in both cases, credential values are never written into the
default-bootstrap configuration/metadata the instance writes to persistent storage on first
start (see FR-025/FR-026).

## Local deployment: `.env` file

The swarm owner supplies credentials to a locally-deployed container (macOS `Container` runtime)
via a `.env` file.

# TODO: finalize and document the exact `.env` variable names once the harness configuration
schema is implemented (e.g. per-model-host keys, GitHub bot token, Jira token).

## AWS deployment: AWS Secrets Manager

The swarm owner supplies credentials to an AWS-deployed instance (ECS Fargate or EKS) via AWS
Secrets Manager. The instance's configuration is set to reference the appropriate secret rather
than embedding credential values directly.

# TODO: finalize and document the exact Secrets Manager path convention once implemented. The
existing AWS architecture draft (`documentation/architectual-decisions-record.md`, ADR-0002)
scopes credentials by path per agent (`/agents/${AGENT_ID}/*`) for the isolation model described
there — confirm whether this same path convention is reused for model-host and identity
credentials, or whether a separate convention is needed.
