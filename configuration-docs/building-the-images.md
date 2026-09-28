# Building and Customizing the Images

You do not need to build anything to use this product — both images are published to GHCR. Build
your own when you need to pin tool versions, add a language runtime your agents need, swap an
installer for an internal mirror, or publish to your own registry.

## Build context: each image's own directory

Both Dockerfiles `COPY` their sidecar files by bare filename, so **the build context is the image's
directory, not the repository root**:

```sh
# Harness-only image
docker build -t my-harness:dev images/harness

# Harness+Paperclip image, built FROM the one above
docker build -t my-paperclip:dev \
  --build-arg BASE_IMAGE=my-harness:dev \
  images/paperclip
```

CI does exactly this. Building with `-f images/harness/Dockerfile .` instead will fail at the first
`COPY`, because `instance.default.yaml` does not exist at the repository root — see ADR-0012.

## The `FROM` relationship

`images/paperclip/Dockerfile` starts with:

```dockerfile
ARG BASE_IMAGE=ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest
FROM ${BASE_IMAGE}
```

The default points at the published harness image, so the paperclip image builds standalone. CI
overrides `BASE_IMAGE` with the **digest** of the harness image it just built, so a CI run can never
accidentally layer a new Paperclip image onto a stale `:latest` (ADR-0006).

Build both locally with `--build-arg BASE_IMAGE=` as shown above so you are testing your own base,
not the published one.

**Gotcha if you use buildx:** the plain `docker build` commands above work because the daemon builds
them and shares one image store, so `BASE_IMAGE=my-harness:dev` resolves to the tag you just built.
`docker buildx build` runs inside its own builder container, which cannot see images in the host
daemon — chaining that way fails with `pull access denied … docker.io/library/my-harness:dev` as it
tries Docker Hub instead. Either stick to plain `docker build` locally, or push the base somewhere the
builder can reach first. CI takes the second route, using a throwaway `registry:2` on localhost.

## Run what you built

```sh
mkdir -p /tmp/agent-data
docker run --rm -it \
  --volume /tmp/agent-data:/data \
  --env-file ./my.env \
  my-harness:dev
```

The container drops to the non-root `agent` user (uid/gid 1000). Your `/data` mount must be writable
by uid 1000 or the `instance.yaml` bootstrap will fail.

To inspect the image without starting Hermes, override the entrypoint:

```sh
docker run --rm -it --entrypoint /bin/bash my-harness:dev
```

Handy checks inside that shell:

```sh
id -u                                       # 1000
command -v hermes omp opencode yq gh        # all resolvable after the privilege drop
source /opt/agentic-team/harness-bootstrap.sh   # exercise the bootstrap without starting Hermes
```

## What to change for a customized build

| Goal | Where |
|---|---|
| Pin a tool to a specific version | The relevant `RUN curl … install` line in `images/harness/Dockerfile`. Each installer is a working **default**, deliberately not pinned, so it is yours to replace. |
| Install a tool from an internal mirror | Same lines — swap the URL. |
| Add a language runtime or SDK your agents need | A new `RUN apt-get install …` in `images/harness/Dockerfile`, before the `USER agent` switch. |
| Change the default instance configuration | `images/harness/instance.default.yaml` — the template written to `/data/instance.yaml` on first start. |
| Change what the bootstrap does | `images/harness/harness-bootstrap.sh`, shared by both images. |
| Add Node.js to the Paperclip image | `images/paperclip/Dockerfile`. See the note below. |

Anything added after `USER agent` in the Dockerfile runs unprivileged; `apt-get` will fail there.
The Paperclip image switches back to `root` for its own install step and then drops privileges
again — follow that pattern if you add privileged steps to it.

## Publishing to your own registry

Retag and push, or fork `.github/workflows/build-and-publish.yml` and change the `REGISTRY` /
`*_IMAGE` environment variables at the top. The workflow's structure is worth keeping:

- **`lint`** — shellcheck on the entrypoints and bootstrap, hadolint on both Dockerfiles.
- **`smoke-build`** — single-arch build of both images, loaded and actually *run*, asserting the
  container comes up as uid 1000, every tool is on `PATH` after the privilege drop, and the
  `instance.yaml` bootstrap writes a config. Nothing is pushed. This catches the failures static
  analysis cannot.
- **`build-harness` / `build-paperclip`** — one job per architecture, each on a **native runner** of
  that architecture (`ubuntu-latest` for amd64, `ubuntu-24.04-arm` for arm64), pushed **by digest with
  no tag**.
- **`merge-harness` / `merge-paperclip`** — assemble the per-architecture digests into one tagged
  multi-arch manifest per image with `docker buildx imagetools create`, and apply the GHCR tags. The
  paperclip build is pinned to the harness *manifest* digest, so each architecture picks up its own
  harness layer.

No QEMU anywhere — see ADR-0016. That matters for these images specifically: every tool installs by
downloading and bootstrapping its own runtime, and emulating all of that was the dominant cost. If you
fork into a private repo where native arm64 runners are not free, either drop arm64 or reinstate
`docker/setup-qemu-action` and a single multi-platform build, and expect it to be slow. Layer caching
(`cache-from`/`cache-to: type=gha`, scoped per architecture) is worth keeping either way.

## Things the build taught us (and might bite your own build)

Each of these was found by actually building, not by reading:

- **`libatomic1` is required.** Hermes's package manager downloads its own Node.js toolchain, which
  links `libatomic.so.1` — absent from `debian:bookworm-slim`. Without it the install dies with
  `✗ pm install failed` and no further explanation. If you change base image, keep this in mind.
- **The Hermes installer hides its errors.** It collapses child output behind a status line and
  reports a one-line reason. The Dockerfile downloads the script and dumps
  `$HERMES_HOME/logs/install.log` on failure so a broken build is diagnosable. Keep that if you edit
  the step.
- **Paperclip needs Node.js and does not bundle it**, and `https://paperclip.ing/install.sh` cannot
  run in a build at all: it sets `NO_PROMPT=1` when there is no TTY and then passes `--no-prompt` to
  the `paperclipai` package, which rejects it. The image installs Node (NodeSource, `ARG NODE_MAJOR`)
  and `npm install -g paperclipai@latest` directly instead — see ADR-0015. If you would rather track
  upstream's script, check whether that flag incompatibility has been fixed first.
- **Tool binaries land in more than one place.** `hermes` and `omp` resolve under
  `/home/agent/.local/bin`, `opencode` under `/home/agent/.opencode/bin`. The image puts both on
  `PATH` (plus `/root/.local/bin`, where the installers ran) and copies root's dotfiles across.

## Still unverified

- **The literal `hermes gateway run --foreground` invocation.** Research confirmed `hermes gateway
  install` sets up a *service*; the foreground form used here as the container's main process was not
  confirmed against upstream docs, and `smoke-build` deliberately does not exercise it (running the
  entrypoint would block). Verify against
  [Hermes's own documentation](https://github.com/nousresearch/hermes-agent) before relying on it.
- **Volume permissions.** `smoke-build` runs without a mounted volume, so it does not prove your bind
  mount, PVC or EFS access point is writable by uid 1000.
- Nothing architecture-specific: `smoke-build` covers `linux/amd64` and `linux/arm64` natively.
