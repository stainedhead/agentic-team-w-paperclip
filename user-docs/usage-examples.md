# Usage Examples

## Example 1: a single-persona Reviewer, harness-only, Anthropic-backed

`instance.yaml`:
```yaml
personas: [Reviewer]
model_host:
  provider: anthropic
  credentials_ref: ANTHROPIC_API_KEY
paperclip:
  agent_id: reviewer-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
identity:
  github_bot_account_ref: GITHUB_PAT
```

`.env`:
```
ANTHROPIC_API_KEY=sk-ant-...
PAPERCLIP_AGENT_API_KEY=pc_agent_...
GITHUB_PAT=ghp_...
```

Run with the harness-only image (no Paperclip needed on this instance — it's registered against
a Paperclip instance running elsewhere):

```sh
container run --name reviewer-01 \
  --volume ~/agentic-team/reviewer-01/data:/data \
  --env-file ~/agentic-team/reviewer-01/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

## Example 2: a multi-persona instance hosting its own Paperclip

`instance.yaml`:
```yaml
personas: [TechLead, Architect]
model_host:
  provider: openrouter
  credentials_ref: OPENROUTER_API_KEY
paperclip:
  agent_id: techlead-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
identity:
  github_bot_account_ref: GITHUB_PAT
```

Run with the harness-plus-Paperclip image, since this instance hosts Paperclip itself:

```sh
container run --name techlead-01 \
  --volume ~/agentic-team/techlead-01/data:/data \
  --env-file ~/agentic-team/techlead-01/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/paperclip:latest
```

## Example 3: AWS ECS Fargate, credentials from Secrets Manager

Same `instance.yaml` shape as above; the only difference is where the `*_ref` names resolve
from. In the ECS task definition's `secrets` block:

```json
{
  "secrets": [
    { "name": "OPENROUTER_API_KEY", "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/model-host-api-key" },
    { "name": "PAPERCLIP_AGENT_API_KEY", "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/paperclip-agent-api-key" },
    { "name": "GITHUB_PAT", "valueFrom": "arn:aws:secretsmanager:...:/agents/techlead-01/github-pat" }
  ]
}
```

See `configuration-docs/deploy-ecs-fargate.md` for the full task-definition example and EFS
persistent-storage setup.
