# Configuration Docs

How a **swarm owner** configures and deploys this platform. For how a developer uses an already
deployed fleet, see [user-docs/](../user-docs/) instead.

Everything here documents deployment; nothing here automates it. Copy-pasteable artifacts live in
[templates/](../templates/).

## Start here

1. **[credentials-and-secrets.md](credentials-and-secrets.md)** — the `*_ref` indirection every other
   page depends on: local `.env`, AWS Secrets Manager, and what the startup bootstrap produces.
2. **[paperclip-agent-registration.md](paperclip-agent-registration.md)** — register an instance's
   agent identity in Paperclip, and the one field that must match on both sides.
3. **[github-cli-and-pat.md](github-cli-and-pat.md)** — the GitHub PAT, its scopes, and how `gh` ends
   up authenticated inside the container.

## Deploying

Pick your target. All three need the same three things — the image, a persistent volume at `/data`,
and credentials in the environment — and differ only in how the last two are attached.

- **[deploy-macos-container.md](deploy-macos-container.md)** — local lab, macOS native `container`
  runtime.
- **[deploy-ecs-fargate.md](deploy-ecs-fargate.md)** — AWS ECS Fargate.
- **[deploy-eks.md](deploy-eks.md)** — AWS EKS, to a configurable account/cluster/namespace.

## Building your own images

- **[building-the-images.md](building-the-images.md)** — build contexts, the `FROM` relationship
  between the two images, pinning tool versions, and publishing to your own registry. You do not need
  this to use the product; you need it to customize it.
