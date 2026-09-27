# Templates

Copy-pasteable starting points. Nothing here is applied automatically — copy a file, fill in the
placeholders, and keep it in your own configuration repository.

Placeholders are written as `<angle-bracketed>` and every file is safe to commit **once you have
replaced them**; none of these files should ever hold a real credential value.

| Path | What it is |
|---|---|
| [`env/.env.example`](env/.env.example) | Credentials for a harness-only instance. |
| [`env/.env.paperclip.example`](env/.env.paperclip.example) | The above plus Paperclip's own boot secrets. |
| [`instance/reviewer-single-persona.yaml`](instance/reviewer-single-persona.yaml) | Minimal `instance.yaml` — one persona, Anthropic-backed. |
| [`instance/techlead-multi-persona.yaml`](instance/techlead-multi-persona.yaml) | Two personas, OpenRouter-backed, custom poll schedule. |
| [`macos-container/run-instance.sh`](macos-container/run-instance.sh) | Create the data volume and start an instance under macOS `container`. |
| [`aws-ecs/task-definition.json`](aws-ecs/task-definition.json) | ECS Fargate task definition with EFS at `/data` and Secrets Manager wiring. |
| [`aws-eks/deployment.yaml`](aws-eks/deployment.yaml) | EKS `PersistentVolumeClaim` + `Deployment` with a Secrets Store CSI mount. |

## How the pieces relate

An instance needs exactly three things, whatever the deployment target:

1. **The image** — `ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` or `.../paperclip:latest`.
2. **A persistent volume at `/data`** — holds `instance.yaml` and tool state across restarts. Without
   it, the instance re-bootstraps a blank configuration every start.
3. **Credentials in its environment** — under the variable names the `*_ref` fields in
   `instance.yaml` point at.

The `instance.yaml` you write is identical across targets; only how the volume is attached and how
credentials reach the environment differ. That is the whole reason for the `*_ref` indirection —
see [configuration-docs/credentials-and-secrets.md](../configuration-docs/credentials-and-secrets.md).

Deployment walkthroughs live in [configuration-docs/](../configuration-docs/); these files are the
artifacts those walkthroughs describe.
