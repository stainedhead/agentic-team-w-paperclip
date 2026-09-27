# Configuration Reference: `instance.yaml`

`/data/instance.yaml`, on the persistent-storage volume you mount at `/data`. This is this
product's *own* configuration surface — it does not restate Hermes's, OMP's, or OpenCode's own
config files (those live at their usual paths inside the container and aren't managed here).

Bootstrapped from a default template on first start if missing; reused as-is on every start
after that (including image updates) — see
`specs/260927-agentic-team-w-paperclip/architecture.md` for the full design rationale.

## Fields

```yaml
personas: [Reviewer, TechLead]
model_host:
  provider: anthropic
  credentials_ref: MODEL_HOST_API_KEY
paperclip:
  agent_id: my-agent-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY
identity:
  github_bot_account_ref: GITHUB_PAT
```

| Field | Type | Meaning |
|---|---|---|
| `personas` | list of strings | One or more of: `CTO`, `Architect`, `TechLead`, `Reviewer`, `Intern`, `DevSupport`, `Researcher`, `Librarian`. |
| `model_host.provider` | string | One of: `aws_bedrock`, `ollama_cloud`, `openrouter`, `anthropic`, `openai`. |
| `model_host.credentials_ref` | string | Name of the credential to use for this provider — an env var name (see `configuration-docs/credentials-and-secrets.md`), never a raw key. |
| `paperclip.agent_id` | string | Must match this instance's registration in Paperclip (a separate step from editing this file — see `getting-started.md`). |
| `paperclip.api_key_ref` | string | Name of the credential holding this instance's Paperclip Agent API key. |
| `identity.github_bot_account_ref` | string | Name of the credential holding the GitHub PAT used for `gh` CLI auth (see `configuration-docs/github-cli-and-pat.md`). |

## What's *not* here

- Raw credential values — always supplied separately (`.env` locally, AWS Secrets Manager in
  AWS), never written into this file.
- Deployment target, compute sizing, networking — this file only configures the instance's own
  behavior, not where/how it's deployed. See `configuration-docs/deploy-*.md`.
- The Paperclip-poll schedule itself — currently a fixed default (every 5 minutes) set by the
  image's bootstrap logic, not yet exposed as a field here. See
  `specs/260927-agentic-team-w-paperclip/architecture.md` if you need to change it (it requires
  editing the entrypoint's `DEFAULT_POLL_CRON`, not `instance.yaml`).
