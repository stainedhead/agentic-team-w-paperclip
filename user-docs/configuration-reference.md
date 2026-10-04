# Configuration Reference: `instance.yaml`

`/data/instance.yaml`, on the persistent volume mounted at `/data`. This is this product's **own**
configuration surface. It deliberately does not restate Hermes's, OMP's or OpenCode's configuration —
those tools keep their own config files at their usual paths inside the container, and are not managed
here (ADR-0011).

Bootstrapped from a default template on first start if missing; reused as-is on every later start,
including across image updates.

## Full example

```yaml
personas: [Reviewer, TechLead]

model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY

paperclip:
  agent_id: my-agent-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
  poll_schedule: "*/5 * * * *"

identity:
  github_bot_account_ref: GITHUB_PAT
```

## Fields

| Field | Type | Default | Meaning |
|---|---|---|---|
| `personas` | list of strings | `[]` | One or more of `CTO`, `Architect`, `TechLead`, `Reviewer`, `Intern`, `DevSupport`, `Researcher`, `Librarian`. Declares which personas this instance is prepared to act as; exported as `AGENT_PERSONAS`. |
| `model_host.provider` | string | `""` | One of `aws_bedrock`, `ollama_cloud`, `openrouter`, `anthropic`, `openai`. Exported as `MODEL_HOST_PROVIDER`. |
| `model_host.credentials_ref` | string | `""` | **Name** of the variable holding the provider's API key — never the key itself. Resolved into `MODEL_HOST_API_KEY`. Leave unset when using an AWS IAM role with Bedrock. |
| `paperclip.agent_id` | string | `""` | Must match this instance's agent registration in Paperclip. Left empty, the instance starts but registers no poll job and receives no work. Exported as `PAPERCLIP_AGENT_ID`. |
| `paperclip.api_key_ref` | string | `""` | **Name** of the variable holding this instance's Paperclip Agent API key. Resolved into `PAPERCLIP_AGENT_API_KEY`. |
| `paperclip.poll_schedule` | string (cron) | `*/5 * * * *` | Schedule for the work-pull job. Empty or absent uses the default. Passed to Hermes unvalidated — an invalid expression surfaces as a Hermes error in the log. |
| `identity.github_bot_account_ref` | string | `""` | **Name** of the variable holding the GitHub PAT. Resolved into `GITHUB_TOKEN`, which `gh` reads natively. |

Every `*_ref` field names a variable; none of them ever holds a value. See
[credentials-and-secrets.md](../configuration-docs/credentials-and-secrets.md).

## What the container does with it

On every start, the bootstrap:

1. writes the default template if `/data/instance.yaml` is absent, otherwise reuses the existing file;
2. resolves each `*_ref` against the container's own environment, **warning** (not failing) on any that
   names a variable which is not set;
3. writes the resolved values to `~/.hermes/.env` (mode `600`, regenerated every start) and exports
   them so Hermes and everything it spawns inherits them;
4. reconciles the Paperclip work-pull cron job with Hermes: creates it if missing, updates its
   schedule or agent id when changed, and removes stale duplicates (or removes it when the agent id
   is unset).

Resulting variables: `AGENT_PERSONAS`, `MODEL_HOST_PROVIDER`, `MODEL_HOST_API_KEY`,
`PAPERCLIP_AGENT_ID`, `PAPERCLIP_AGENT_API_KEY`, `GITHUB_TOKEN`. Your own prompts, skills and tool
configuration can rely on these.

**Changes take effect on restart**, not live — the file is read once at startup.

## Not configured here

| Thing | Where instead |
|---|---|
| Credential **values** | `.env` locally, Secrets Manager in AWS — [credentials-and-secrets.md](../configuration-docs/credentials-and-secrets.md) |
| Paperclip's own boot secrets (`BETTER_AUTH_SECRET`, `PAPERCLIP_TOOL_ACTION_SIGNING_SECRET`) | Container environment — same page |
| Deployment target, compute sizing, networking, volumes | [configuration-docs/deploy-*.md](../configuration-docs/) |
| The agent's role and reporting chain | Paperclip — [paperclip-agent-registration.md](../configuration-docs/paperclip-agent-registration.md) |
| Hermes / OMP / OpenCode native settings | Each tool's own config inside the container |
| Installed tool versions | The Dockerfile — [building-the-images.md](../configuration-docs/building-the-images.md) |
