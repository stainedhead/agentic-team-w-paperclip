# Configuring Credentials and Secrets

An instance needs credentials for its model host, its Paperclip Agent API key, and its GitHub PAT.
How those are *sourced* depends on the deployment target; how they are *referenced* does not. That
split is the whole design here, and it is why one `instance.yaml` works unchanged locally and in AWS.

## The `*_ref` indirection

`/data/instance.yaml` never holds a credential value — only the **name** of the variable that does:

```yaml
model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY    # <- a name, not a value
paperclip:
  agent_id: reviewer-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY   # <- a name, not a value
identity:
  github_bot_account_ref: GITHUB_PAT     # <- a name, not a value
```

At startup, `images/harness/harness-bootstrap.sh` resolves each `*_ref` against the container's
**own process environment**. Because every deployment target can put variables in a container's
environment, only the mechanism differs per target — never the config file.

The names are entirely yours to choose. They are not predefined by this product; they only have to
match between `instance.yaml` and whatever populates the environment.

Two properties worth relying on:

- **A `*_ref` naming a variable that isn't set produces a warning, not a crash.** The container
  starts with its other credentials working and says which reference failed — check `container logs`
  for `WARNING: ... references ...`. This is the most common misconfiguration and it used to be
  silent.
- **`instance.yaml` is never written back to.** Credential values are read, resolved into the
  container's environment, and never persisted into the config file on your volume.

## What the bootstrap produces

Resolved values are written to a generated env file (`~/.hermes/.env`, mode `600`, regenerated on
every start) **and** exported into the environment inherited by Hermes and everything it spawns:

| Variable | From |
|---|---|
| `AGENT_PERSONAS` | `personas`, comma-joined — e.g. `TechLead,Architect` |
| `MODEL_HOST_PROVIDER` | `model_host.provider` |
| `MODEL_HOST_API_KEY` | resolved from `model_host.credentials_ref` |
| `PAPERCLIP_AGENT_ID` | `paperclip.agent_id` |
| `PAPERCLIP_AGENT_API_KEY` | resolved from `paperclip.api_key_ref` |
| `GITHUB_TOKEN` | resolved from `identity.github_bot_account_ref` — the name `gh` reads natively |

Your own prompts, skills and tool configuration can rely on these being present. This project
deliberately does **not** write into Hermes's, OMP's or OpenCode's native config files — see
ADR-0011 for why.

## Local deployment: a `.env` file

Start from [`templates/env/.env.example`](../templates/env/.env.example) (or
[`.env.paperclip.example`](../templates/env/.env.paperclip.example) for the Paperclip variant):

```
MODEL_HOST_API_KEY=<your model host key>
PAPERCLIP_AGENT_API_KEY=<your Paperclip agent API key>
GITHUB_PAT=<your GitHub PAT>
```

Pass it with `--env-file`. The repository's `.gitignore` excludes `.env` and `*.env` so a filled-in
copy cannot be committed by accident; only `*.example` files are tracked.

For `model_host.provider: aws_bedrock`, prefer an IAM role over static keys — see below.

## AWS deployment: Secrets Manager

Inject each secret as an environment variable at the task/pod level — ECS's `secrets` block, or the
Secrets Store CSI Driver / External Secrets Operator on EKS — using the **same variable names** as
the `*_ref` fields. The entrypoint needs no AWS-specific branching as a result.

**Default path convention**, reusing the per-agent isolation scheme in ADR-0002/ADR-0009:

```
/agents/<agent-id>/model-host-api-key
/agents/<agent-id>/paperclip-agent-api-key
/agents/<agent-id>/github-pat
```

Map each to the matching variable name (`/agents/reviewer-01/model-host-api-key` →
`MODEL_HOST_API_KEY`). This is a default, not a requirement — a shared model-host key across agents
is a reasonable deviation, as long as the mapping into the container's environment still matches the
`*_ref` names.

Working examples: [`templates/aws-ecs/`](../templates/aws-ecs/) and
[`templates/aws-eks/`](../templates/aws-eks/).

**For AWS Bedrock as the model host**, prefer the task/pod IAM role (ECS task role, EKS IRSA or Pod
Identity) over static keys: grant it `bedrock:InvokeModel` and leave `model_host.credentials_ref`
unset. The AWS SDKs pick the role credentials up automatically, so there is no key to rotate or leak.

## Paperclip's own boot secrets (harness+Paperclip image only)

The Paperclip **server** — not this product's `instance.yaml` — requires two secrets just to start:
`BETTER_AUTH_SECRET` and `PAPERCLIP_TOOL_ACTION_SIGNING_SECRET`. They sign sessions and tool-action
tokens, so they must stay **stable across restarts** of the same instance; changing them invalidates
live sessions.

- **Recommended:** supply both as environment variables, the same way as every other credential
  here, generated once each with `openssl rand -hex 32`. A supplied value always wins and is never
  written to the instance's volume.
- **Fallback:** if either is unset, the entrypoint generates *just that one* on first boot and
  persists it to `${PAPERCLIP_HOME}/.secrets/<NAME>` (mode `600`, in a `700` directory, on the same
  `/data` volume), reusing it on later starts. Each secret is handled independently, so supplying one
  and letting the other be generated is fine.

The fallback works, but the secret then lives only on that instance's volume rather than in your
secret store — supply them explicitly for anything beyond local experimentation.

No `DATABASE_URL` is needed: Paperclip ships an embedded PostgreSQL.

## Rotating a credential

1. Update the value in your `.env` or secret store — `instance.yaml` does not change, since it only
   names the variable.
2. Restart the instance. The bootstrap re-resolves every `*_ref` and regenerates the env file on
   every start, so there is no cached copy to clear.

The exception is Paperclip's two boot secrets: rotating those invalidates existing sessions, and if
you are using the generated fallback you must delete the file under
`${PAPERCLIP_HOME}/.secrets/` for a new one to be generated.
