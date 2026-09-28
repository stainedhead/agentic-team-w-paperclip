# Getting Started

Running your first instance, end to end. The steps are the same on every deployment target —
credentials, `instance.yaml`, Paperclip registration — and only the "run the container" step differs.
This page uses macOS `container`; for AWS see
[deploy-ecs-fargate.md](../configuration-docs/deploy-ecs-fargate.md) or
[deploy-eks.md](../configuration-docs/deploy-eks.md).

## 1. Pick an image

| Image | Use when |
|---|---|
| `ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` | The normal fleet instance. Hermes, OMP and OpenCode CLI; Hermes runs on start. Paperclip runs elsewhere. |
| `ghcr.io/stainedhead/agentic-team-w-paperclip/paperclip:latest` | This instance should also **host Paperclip** itself. Both run on start. |

Most fleets have one Paperclip (or use a hosted one) and many harness instances. Start with the
harness image unless you are also standing Paperclip up here.

## 2. Set up credentials

```sh
mkdir -p ~/agentic-team/my-agent/data
cp templates/env/.env.example ~/agentic-team/my-agent/.env
```

Fill it in. At minimum you need a model-host API key; add the Paperclip agent key and GitHub PAT when
you have them. Details: [credentials-and-secrets.md](../configuration-docs/credentials-and-secrets.md).

The variable names are yours to choose — they only have to match the `*_ref` fields you set in step 4.

## 3. Run the container

```sh
container run --detach \
  --name my-agent \
  --volume ~/agentic-team/my-agent/data:/data \
  --env-file ~/agentic-team/my-agent/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

The `--volume` mount is what makes `instance.yaml` and tool state survive restarts — without it every
start begins from a blank configuration. Full recipe, including a script that does all of this:
[deploy-macos-container.md](../configuration-docs/deploy-macos-container.md).

## 4. Configure the instance

First start writes a default configuration to the volume — on your host at
`~/agentic-team/my-agent/data/instance.yaml`. Edit it:

```yaml
personas: [Reviewer]
model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY
paperclip:
  agent_id: reviewer-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
  poll_schedule: ""            # empty = every 5 minutes
identity:
  github_bot_account_ref: GITHUB_PAT
```

Then restart so it is applied:

```sh
container stop my-agent && container start my-agent
```

Your edits are reused on every later start, never overwritten. Every field:
[configuration-reference.md](configuration-reference.md). Filled-in examples:
[`templates/instance/`](../templates/instance/).

## 5. Register the agent with Paperclip

Container configuration and Paperclip identity are **two separate setups that must agree**:
`paperclip.agent_id` above has to match the agent's id in Paperclip's roster, or the instance polls
for work that will never be addressed to it.

See [paperclip-agent-registration.md](../configuration-docs/paperclip-agent-registration.md) for the
UI and CLI routes and for getting the Agent API key.

Once the id matches and the container has restarted, the Hermes cron job pulls assigned work on its
schedule — nothing further to wire up.

## 6. Confirm it is working

```sh
container logs my-agent
```

The startup log is the main diagnostic. Expect to see:

```
[bootstrap] reusing existing /data/instance.yaml
[bootstrap] wrote /home/agent/.hermes/.env (personas='Reviewer', model host='anthropic', paperclip agent='reviewer-01')
[bootstrap] registering Paperclip poll job on schedule '*/5 * * * *'
```

Then:

```sh
container exec my-agent cat /home/agent/.hermes/cron/jobs.json   # the poll job as Hermes stored it
container exec my-agent gh auth status                            # GitHub auth, if configured
```

## When something is wrong

| Symptom | Cause |
|---|---|
| `WARNING: … references 'X', but no such variable is set` | The `*_ref` name in `instance.yaml` and the name in your `.env` disagree. The container still starts — fix the name and restart. |
| `personas='none', model host='unset', paperclip agent='unset'` | You are running the default template — either the edit did not land in the mounted directory, or the container was not restarted. |
| `paperclip.agent_id is unset … skipping poll-job registration` | Expected before step 5. The instance is idle by design until an agent id is set. |
| Permission error writing `/data/instance.yaml` | The volume is not writable by uid 1000, the user the container runs as. |
| Instance runs but never gets work | `paperclip.agent_id` does not match a registered agent, or nothing is assigned to it in Paperclip. |

The log reports what the container actually read from `instance.yaml`, so comparing that against what
you think you wrote resolves most configuration problems in one step.

## Next

- [usage-examples.md](usage-examples.md) — worked setups, single- and multi-persona.
- [configuration-reference.md](configuration-reference.md) — every field and what consumes it.
- [building-the-images.md](../configuration-docs/building-the-images.md) — pin tool versions or add
  your own runtime.
