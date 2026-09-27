# Deploying to AWS ECS Fargate

Running an instance as an ECS Fargate task. An example to adapt — you provision the surrounding AWS
infrastructure (task definition, IAM roles, EFS access point, Secrets Manager entries); this product
does not ship a CDK or Terraform module for it.

Ready-to-edit task definition and a placeholder table:
[`templates/aws-ecs/`](../templates/aws-ecs/).

## Shape of a deployment

One ECS **service** per agent instance, each with:

| Piece | Why |
|---|---|
| Its own **task role** | The agent's runtime identity. Scope it to just what that persona may touch — this per-agent boundary is the isolation model these docs assume (ADR-0002). |
| Its own **EFS access point** at `/data` | Persistent `instance.yaml` and tool state. One per instance; no sharing. |
| Its own **secret path** | `/agents/<agent-id>/*` by convention, readable only by that agent's roles. |
| **Desired count: 1** | These are stateful singletons. Two tasks sharing a volume and a `paperclip.agent_id` would both claim the same work. |

## Persistent storage

Mount an EFS access point at `/data` via the task definition's `volumes`/`mountPoints`. Configure the
access point to enforce POSIX **uid/gid 1000:1000** — the uid the images run as — with a dedicated
root directory per agent (e.g. `/agents/reviewer-01`) and mask `0750`. Get this wrong and the
container cannot write `/data/instance.yaml`; that is the first thing to check if a task starts and
immediately misbehaves.

Enable `transitEncryption` and IAM authorization, as the template does.

## Credentials

Reference each Secrets Manager secret in the task definition's `secrets` block, mapping it to the
environment variable name used by the corresponding `*_ref` field in `instance.yaml`. See
[credentials-and-secrets.md](credentials-and-secrets.md) for the path convention and for why the same
`instance.yaml` works here and locally.

For **Bedrock** as the model host, grant `bedrock:InvokeModel` on the *task role* and leave
`model_host.credentials_ref` unset rather than storing static keys.

The **execution role** needs `secretsmanager:GetSecretValue` on those secret ARNs (plus KMS decrypt if
they use a customer-managed key) — it is what injects them, not the task role.

## Image

`ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` or `.../paperclip:latest`. Both are
published for `linux/amd64` and `linux/arm64`; ARM64 (Graviton) is the cheaper Fargate option, set via
`runtimePlatform.cpuArchitecture`.

Pin by digest (`image@sha256:…`) for anything you need to reproduce — `:latest` moves under you. Each
CI build also publishes a `sha-<commit>` tag.

GHCR pull access: public packages need nothing; a private package needs a `repositoryCredentials`
entry referencing a Secrets Manager secret holding a PAT with `read:packages`.

## Getting the first configuration onto the volume

A fresh EFS access point is empty, so the first task start writes the default `instance.yaml` and then
runs with it — which does nothing useful until you fill it in. Either:

- **pre-seed it** — write your `instance.yaml` to the access point before first launch (from a
  bastion, a one-off task, or an EFS-mounted EC2 instance); or
- **let it bootstrap, then edit** — start the task once, edit the file on EFS, and restart the service.

Pre-seeding is the better fit for anything repeatable: keep each agent's `instance.yaml` in your own
configuration repository alongside the task definition.

## Observability

Use the `awslogs` driver, one log group per agent (`/agentic-team/<agent-name>`), as in the template.
The startup bootstrap logs the personas, model host and agent id it resolved and warns about any
unresolvable `*_ref` — those lines are how you confirm a task is configured as intended.

## The harness+Paperclip variant

It runs two processes and an embedded PostgreSQL, so give it more than the template's starting
1024 CPU / 2048 MB, and add Paperclip's two boot secrets (`BETTER_AUTH_SECRET`,
`PAPERCLIP_TOOL_ACTION_SIGNING_SECRET`) to the `secrets` block so they stay stable across task
replacements. If either process exits, the container exits — ECS then restarts the task per the
service's policy, which is the intended behavior (ADR-0013).

## Updating

Register a new task definition revision pointing at the new image tag or digest and update the
service. The existing EFS access point and its `/data/instance.yaml` are reused unchanged — an image
update never resets an instance's configuration.
