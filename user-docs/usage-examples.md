# Usage Examples

Four worked setups. Each is a complete `instance.yaml` + credentials + run command. Copyable versions
of the config files live in [`templates/`](../templates/).

## 1. A single-persona Reviewer, harness-only, Anthropic-backed

The common fleet instance: one persona, no Paperclip here (it runs elsewhere).

`instance.yaml` — [`templates/instance/reviewer-single-persona.yaml`](../templates/instance/reviewer-single-persona.yaml):
```yaml
personas: [Reviewer]
model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY
paperclip:
  agent_id: reviewer-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
identity:
  github_bot_account_ref: GITHUB_PAT
```

`.env`:
```
MODEL_HOST_API_KEY=sk-ant-...
PAPERCLIP_AGENT_API_KEY=pc_agent_...
GITHUB_PAT=ghp_...
```

```sh
container run --detach --name reviewer-01 \
  --volume ~/agentic-team/reviewer-01/data:/data \
  --env-file ~/agentic-team/reviewer-01/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

## 2. A multi-persona instance, OpenRouter-backed, polling faster

One container acting as both TechLead and Architect, checking for work every two minutes.

`instance.yaml` — [`templates/instance/techlead-multi-persona.yaml`](../templates/instance/techlead-multi-persona.yaml):
```yaml
personas: [TechLead, Architect]
model_host:
  provider: openrouter
  credentials_ref: MODEL_HOST_API_KEY
paperclip:
  agent_id: techlead-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
  poll_schedule: "*/2 * * * *"
identity:
  github_bot_account_ref: GITHUB_PAT
```

Same run command as above with the names changed. How you split personas across instances is your
team-design call: fewer multi-persona instances cost less to run; one instance per persona isolates
failures and lets you scale personas independently.

## 3. An instance that also hosts Paperclip

Use the `paperclip` image variant. The `instance.yaml` is unchanged — the difference is the image and
two extra environment variables.

`.env` — [`templates/env/.env.paperclip.example`](../templates/env/.env.paperclip.example):
```
MODEL_HOST_API_KEY=sk-or-...
PAPERCLIP_AGENT_API_KEY=pc_agent_...
GITHUB_PAT=ghp_...

# Paperclip's own boot secrets — generate each once with `openssl rand -hex 32`.
# They sign sessions, so they must stay stable across restarts.
BETTER_AUTH_SECRET=...
PAPERCLIP_TOOL_ACTION_SIGNING_SECRET=...
```

```sh
container run --detach --name orchestrator-01 \
  --volume ~/agentic-team/orchestrator-01/data:/data \
  --env-file ~/agentic-team/orchestrator-01/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/paperclip:latest
```

Paperclip's data (including its embedded PostgreSQL) lands in `/data/paperclip`, on the same volume as
`instance.yaml` — so back up or snapshot that volume as a unit. Leaving the two secrets unset works:
the entrypoint generates and persists them on the volume, which is fine for local experimentation and
not where you want a production secret living.

## 4. AWS ECS Fargate, credentials from Secrets Manager

The **same `instance.yaml`** as example 2, unchanged. Only where the `*_ref` names resolve from is
different — the task definition's `secrets` block:

```json
{
  "secrets": [
    { "name": "MODEL_HOST_API_KEY",     "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/model-host-api-key" },
    { "name": "PAPERCLIP_AGENT_API_KEY", "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/paperclip-agent-api-key" },
    { "name": "GITHUB_PAT",             "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/github-pat" }
  ]
}
```

That portability is the point of the `*_ref` indirection: the instance's configuration is target
agnostic, and only the credential delivery mechanism changes.

Full task definition: [`templates/aws-ecs/`](../templates/aws-ecs/). Walkthrough including the EFS
volume and IAM roles: [deploy-ecs-fargate.md](../configuration-docs/deploy-ecs-fargate.md). For EKS,
[`templates/aws-eks/`](../templates/aws-eks/) and [deploy-eks.md](../configuration-docs/deploy-eks.md).

## Running a fleet

Instances share nothing. Per instance: a distinct `--name`, its own volume, its own `.env`, and a
**distinct `paperclip.agent_id`** — two instances sharing an id would both claim the same work.

A small starting fleet might be one `paperclip` instance plus a handful of harness instances, e.g.
`architect-01`, `techlead-01`, `reviewer-01`, `intern-01`. Which personas you actually need, and how
many of each, is your design decision — this product prescribes no org chart.
