# ECS Fargate template

`task-definition.json` is a deliberately **plain, valid** task definition — no comment keys, because
the ECS API rejects unknown fields and `aws ecs register-task-definition --cli-input-json` would
fail on them. All the explanation lives here instead.

Walkthrough and reasoning: [configuration-docs/deploy-ecs-fargate.md](../../configuration-docs/deploy-ecs-fargate.md).
This is a starting example to adapt — this project documents deployment rather than automating it.

## Use it

Replace every `REPLACE-…` placeholder, then:

```sh
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

| Placeholder | Value |
|---|---|
| `REPLACE-agent-name` | This instance's name, e.g. `reviewer-01`. Use the same string as `paperclip.agent_id` in its `instance.yaml` so logs, secrets and the roster line up. |
| `REPLACE-account-id` | Your AWS account ID. |
| `REPLACE-region` | e.g. `us-east-1`. |
| `REPLACE-ecs-task-execution-role` | An existing ECS task execution role — it pulls the image and reads the secrets. |
| `REPLACE-fs-id` | The EFS filesystem ID backing `/data`. |
| `REPLACE-fsap-id` | The EFS **access point** for this agent (one per instance). |

## What each part is doing

**`runtimePlatform.cpuArchitecture: ARM64`** — the images are published multi-arch
(`linux/amd64` + `linux/arm64`). ARM64 is the cheaper Fargate option (Graviton); switch to
`X86_64` if you need it.

**Two roles, not one.** `executionRoleArn` is the infrastructure's identity — pull the image, read
the secrets. `taskRoleArn` is *the agent's own* identity at runtime. Give each agent its own task
role scoped to just what that persona may touch: that per-agent boundary is the isolation model
this project's documentation assumes, and it is what keeps one misbehaving agent from reaching
another's resources.

**The EFS volume at `/data`** is what makes `instance.yaml` and tool state survive restarts and
image updates. Without it, every start re-bootstraps a blank configuration. Configure the access
point to enforce POSIX **uid/gid 1000:1000** — the uid the images run as — or the container will not
be able to write to it.

**`secrets[].name` must match the `*_ref` values** in that instance's `/data/instance.yaml`. The
names are yours to choose; the ones here match [`templates/instance/`](../instance/). The
`/agents/<agent-name>/*` secret path is a convention, not a requirement — see
[credentials-and-secrets.md](../../configuration-docs/credentials-and-secrets.md).

## For the harness+Paperclip image

Change `image` to `.../paperclip:latest` and add Paperclip's own boot secrets, which must stay
stable across restarts:

```json
{ "name": "BETTER_AUTH_SECRET",
  "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:/agents/AGENT/better-auth-secret" },
{ "name": "PAPERCLIP_TOOL_ACTION_SIGNING_SECRET",
  "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:/agents/AGENT/paperclip-tool-action-signing-secret" }
```

That variant runs two processes and needs more headroom — raise `cpu`/`memory` above the
1024/2048 starting point, and remember Paperclip runs an embedded PostgreSQL.

## Pin the image for real deployments

`:latest` is convenient for a first run and wrong for anything you need to reproduce. Pin by digest
instead:

```
ghcr.io/stainedhead/agentic-team-w-paperclip/harness@sha256:<digest>
```

Every CI build also publishes a `sha-<commit>` tag if you would rather track commits than digests.
