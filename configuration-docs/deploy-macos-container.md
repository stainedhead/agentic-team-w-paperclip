# Deploying Locally with macOS `container`

Running an instance under macOS's native `container` runtime — the local-lab target. An example to
adapt; this product documents deployment rather than automating it.

Scripted version of everything below:
[`templates/macos-container/run-instance.sh`](../templates/macos-container/run-instance.sh).

## Persistent storage

`container` bind-mounts a host directory the same way Docker does. Use one as the backing store for
`/data`, so `instance.yaml` and tool state survive restarts and image updates:

```sh
mkdir -p ~/agentic-team/<agent-name>/data

container run --detach \
  --name <agent-name> \
  --volume ~/agentic-team/<agent-name>/data:/data \
  --env-file ~/agentic-team/<agent-name>/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

Swap the image for `.../paperclip:latest` to run the harness+Paperclip variant.

**This mount is not optional.** Without it the instance re-bootstraps a blank configuration on every
start, and any tool state — including Paperclip's database on the paperclip variant — is lost with
the container.

The container runs as uid/gid **1000**. A directory you created under your own home is writable by
your user, and `container` maps it through, so this normally just works; if you see permission errors
writing `/data/instance.yaml`, that mapping is the thing to check.

## First start and configuration

On first start the entrypoint writes a default `instance.yaml` into the volume — visible on the host
at `~/agentic-team/<agent-name>/data/instance.yaml`. Edit it (personas, model host,
`paperclip.agent_id`), then restart:

```sh
container stop <agent-name> && container start <agent-name>
```

Your edits are reused, never overwritten. See
[user-docs/configuration-reference.md](../user-docs/configuration-reference.md) for the fields, and
[`templates/instance/`](../templates/instance/) for filled-in examples.

## Credentials

Copy [`templates/env/.env.example`](../templates/env/.env.example) to
`~/agentic-team/<agent-name>/.env` and fill it in — `--env-file` above is how it reaches the
container. See [credentials-and-secrets.md](credentials-and-secrets.md).

## Checking it came up

```sh
container logs <agent-name>
container exec <agent-name> cat /home/agent/.hermes/cron/jobs.json   # the Paperclip poll job
container exec <agent-name> gh auth status                            # GitHub auth, if configured
```

The startup log reports the personas, model host and agent id it resolved, plus a warning for any
`*_ref` naming a variable that is not set — which is where a `.env` typo shows up.

## Running several instances

One container, one volume, one `.env` per instance — they share nothing. Give each a distinct
`--name`, its own directory under `~/agentic-team/`, and a distinct `paperclip.agent_id`. Two
instances sharing an `agent_id` would both claim the same work.

## Updating

```sh
container stop <agent-name>
# pull the new image tag
container run ... # same --volume and --env-file
```

The persisted `/data/instance.yaml` is reused, not regenerated — an image update never resets an
instance's configuration.
