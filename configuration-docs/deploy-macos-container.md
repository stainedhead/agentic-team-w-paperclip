# Deploying Locally with macOS `Container`

Example for running either image variant (FR-016) as a container under macOS's native
`container` runtime. This is an example the swarm owner adapts — this product does not automate
deployment (see the PRD's deployment-automation non-goal).

## Persistent storage recipe (resolves the local-mode open question)

`container` supports bind-mounting a host directory into the container the same way Docker
does. Use a host directory as the backing store for `/data` (FR-024), so `/data/instance.yaml`
and any tool-specific state survive container restarts and image updates:

```sh
mkdir -p ~/agentic-team/<agent-name>/data

container run \
  --name <agent-name> \
  --volume ~/agentic-team/<agent-name>/data:/data \
  --env-file ~/agentic-team/<agent-name>/.env \
  ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
```

(Swap the image for `.../paperclip:latest` to run the harness+Paperclip variant.)

On first run, the entrypoint bootstraps `/data/instance.yaml` from the image's default template
(FR-025); edit that file on the host at `~/agentic-team/<agent-name>/data/instance.yaml` to set
personas, model host, and credential references, then restart the container — FR-026 means it
will be reused, not overwritten.

## Credentials

See `credentials-and-secrets.md`'s local `.env` section — the `--env-file` flag above is how
those variables reach the container.

## Updating

Per FR-023: `container stop <agent-name>`, pull the new image, `container run` again with the
same `--volume` — the persisted `/data/instance.yaml` is reused (FR-026), not regenerated.
