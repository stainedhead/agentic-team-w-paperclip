# Getting Started

This walks through running your first harness instance locally. For AWS targets, see
`configuration-docs/deploy-ecs-fargate.md` or `deploy-eks.md` instead — the steps below (credentials,
`instance.yaml`, Paperclip registration) are the same regardless of deployment target; only the
container-run step differs.

## 1. Pick an image

- `ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` — Hermes, OMP, and OpenCode CLI;
  Hermes runs on startup. Use this if Paperclip is already running elsewhere (or you're only
  using Jira/GitHub directly, without Paperclip).
- `ghcr.io/stainedhead/agentic-team-w-paperclip/paperclip:latest` — everything in the harness
  image, plus Paperclip; both run on startup. Use this if you want this instance to also host
  Paperclip itself.

## 2. Set up credentials

Create a `.env` file with whatever credentials you'll reference from `instance.yaml` — see
`configuration-docs/credentials-and-secrets.md`. At minimum you'll need a model-host API key.

## 3. Run the container

```sh
mkdir -p ~/agentic-team/my-agent/data

container run \
  --name my-agent \
  --volume ~/agentic-team/my-agent/data:/data \
  --env-file ~/agentic-team/my-agent/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

See `configuration-docs/deploy-macos-container.md` for the full recipe (including why the
`--volume` mount matters — it's what makes `/data/instance.yaml` and any tool state survive a
restart).

## 4. Configure the instance

On first start, the entrypoint writes a default `/data/instance.yaml` to
`~/agentic-team/my-agent/data/instance.yaml` on your host. Edit it — see
`configuration-reference.md` for the full field reference — then restart the container; your
edits are reused, not overwritten (that's the point of the persistent volume).

## 5. Register the agent with Paperclip

Registering the instance's identity and persona/role in Paperclip is a separate step from
container configuration — see `specs/260927-agentic-team-w-paperclip/research.md` for the
`paperclipai agent create`/`agent hire` commands. Once registered, the instance's Hermes cron
job (running every 5 minutes by default) starts retrieving assigned work automatically — no
further steps needed.

## Verifying it's working

```sh
container exec my-agent cat ~/.hermes/cron/jobs.json   # confirm the Paperclip-poll job was created
container exec my-agent gh auth status                  # confirm GitHub CLI authentication (if configured)
container logs my-agent                                  # watch Hermes's own logs
```

(There may also be a `hermes cron list`-style command for this — check Hermes's own CLI help;
the jobs file above is the one path confirmed directly from research, see
`specs/260927-agentic-team-w-paperclip/research.md`.)
