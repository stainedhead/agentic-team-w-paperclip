# Deploying to AWS ECS Fargate

Example for running either image variant (FR-016) as an ECS Fargate task, consistent with
`documentation/technical-architecture.md`'s architecture (per-persona IAM task role, EFS Access
Point, Cloud Map service discovery). This product does not automate this deployment — the swarm
owner provisions the surrounding AWS infrastructure (task definition, IAM role, EFS access point,
Secrets Manager entries) using this as a starting example, not a Terraform/CDK module this
product ships.

## Persistent storage (FR-024)

Mount an EFS Access Point at `/data` in the task definition's `volumes`/`mountPoints`, one access
point per agent instance, following the same per-persona isolation pattern already described in
`documentation/technical-architecture.md` (`/agents/<persona>` root directory, POSIX UID/GID
1000:1000, permission mask 0750).

## Credentials (FR-028)

Reference each Secrets Manager secret in the task definition's `secrets` block, mapped to the
environment variable name used in `instance.yaml`'s `*_ref` fields — see
`credentials-and-secrets.md`'s AWS section for the default path convention
(`/agents/${AGENT_ID}/*`).

## Image

Pull from GHCR: `ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` or
`.../paperclip:latest` (FR-030). Requires the task execution role to have pull access configured
for GHCR (either a public image, or an `ecs.amazonaws.com` registry credential referencing a PAT
with `read:packages`).

## Updating (FR-023)

Deploy a new task definition revision referencing the new image tag/digest; the existing EFS
Access Point (and its `/data/instance.yaml`) is reused unchanged (FR-026).
