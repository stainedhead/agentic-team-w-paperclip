# Configuring Credentials and Secrets

A harness or harness+Paperclip instance needs credentials for its configured model host, its
Paperclip Agent API key, its GitHub PAT (see `github-cli-and-pat.md`), and (via Paperclip's own
connector) Jira. Per `agentic-team-w-paperclip-PRD.md` (FR-027/FR-028), how those are sourced
depends on the deployment target — but in both cases, credential values are never written into
the default-bootstrap configuration/metadata the instance writes to persistent storage on first
start (see FR-025/FR-026).

## How this fits together

The instance configuration file (`/data/instance.yaml`, on the persistent-storage volume) never
holds a raw credential value — only a `*_ref` field naming which credential to use:

```yaml
model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY   # <- a name, not a value
paperclip:
  agent_id: ...
  api_key_ref: PAPERCLIP_AGENT_API_KEY  # <- a name, not a value
identity:
  github_bot_account_ref: GITHUB_PAT    # <- a name, not a value
```

The container's entrypoint (`images/harness/harness-bootstrap.sh`) resolves each `*_ref` against
its **own process environment** — which is populated the same way regardless of deployment
target, just via a different mechanism per target (below). This is why the same `instance.yaml`
works unmodified whether the container runs locally or in AWS.

## Local deployment: `.env` file

The swarm owner supplies a `.env` file to a locally-deployed container (macOS `Container`
runtime), with one line per credential referenced in `instance.yaml`:

```
# .env
MODEL_HOST_API_KEY=<your model host key>
PAPERCLIP_AGENT_API_KEY=<your Paperclip agent API key>
GITHUB_PAT=<your GitHub PAT — see github-cli-and-pat.md>
```

The variable names must match whatever `*_ref` names are used in `instance.yaml` — they're
arbitrary strings the swarm owner picks, not predefined by this product.

## AWS deployment: AWS Secrets Manager

The swarm owner supplies credentials to an AWS-deployed instance (ECS Fargate or EKS) via AWS
Secrets Manager, injected into the container as environment variables at the task-definition
level (ECS `secrets` block / EKS Secrets Store CSI driver or External Secrets Operator) — using
the *same* variable names as the `*_ref` fields in `instance.yaml`, so the entrypoint logic needs
no AWS-specific branching.

**Path convention (default — reuses the existing isolation model):** each credential is stored as
its own Secrets Manager secret under the same per-agent path scheme as
`documentation/architectual-decisions-record.md`'s ADR-0002 (`/agents/${AGENT_ID}/*`):

```
/agents/${AGENT_ID}/model-host-api-key
/agents/${AGENT_ID}/paperclip-agent-api-key
/agents/${AGENT_ID}/github-pat
```

The task definition (ECS) or Secrets Store CSI mount (EKS) maps each secret to the matching
environment variable name used as the `*_ref` in `instance.yaml` (e.g.
`/agents/${AGENT_ID}/model-host-api-key` → env var `MODEL_HOST_API_KEY`). This is a default the
swarm owner can change — e.g. a shared model-host key across agents instead of one per agent —
as long as the mapping into the container's environment still matches the `*_ref` names in
`instance.yaml`.

## Paperclip's own boot secrets (harness+Paperclip image only)

Verified 2026-09-27 against Paperclip's own `doc/DOCKER.md`: the embedded Paperclip server itself
(not this product's `instance.yaml`) requires two secrets just to boot —
`BETTER_AUTH_SECRET` and `PAPERCLIP_TOOL_ACTION_SIGNING_SECRET` — used to sign sessions/tokens,
so they must stay **stable across restarts** of the same instance, not regenerated each time.

- **Recommended**: supply both directly as environment variables (`.env` locally, Secrets
  Manager/ECS `secrets` block in AWS — same mechanism as every other credential here), generated
  once with `openssl rand -hex 32` each.
- **Fallback**: if not supplied, `images/paperclip/entrypoint.sh` generates them on first boot
  and persists them to `${PAPERCLIP_HOME}/.generated-secrets.env` (under the same `/data`
  persistent-storage volume as `instance.yaml`), reusing them on subsequent starts. This works,
  but means the secret lives only on that instance's volume rather than in the swarm owner's own
  secret store — prefer supplying them explicitly for anything beyond local experimentation.

No `DATABASE_URL` is needed to boot — Paperclip uses an embedded PostgreSQL by default.
