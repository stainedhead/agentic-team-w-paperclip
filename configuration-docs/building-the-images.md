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
- **`build-and-publish`** — multi-arch (`linux/amd64` + `linux/arm64`) via QEMU, harness digest
  pinned into the paperclip build, pushed to GHCR. Skipped on pull requests.

Multi-arch builds under QEMU are slow — each installer bootstraps its own runtime under emulation.
The workflow uses GitHub Actions cache (`cache-from`/`cache-to: type=gha`) to keep that tolerable;
keep it if you fork.

## Known unverified points

These are honest gaps, not oversights, and the `smoke-build` job exists to close the first two:

- **Whether Paperclip's installer brings its own Node.js.** The entrypoint invokes Paperclip as
  `npx paperclipai <verb>` and fails fast with a clear message if `npx` is missing; upstream does not
  document this. If the smoke test fails on it, add Node.js to `images/paperclip/Dockerfile`.
- **Whether each installer's binaries remain on `PATH` after the privilege drop.** The installers run
  as root; the image adds `/home/agent/.local/bin`, `/home/agent/.opencode/bin` and
  `/root/.local/bin` to `PATH` and copies root's dotfiles across to cover the likely locations.
- **The literal `hermes gateway run --foreground` invocation.** Research confirmed `hermes gateway
  install` sets up a *service*; the foreground form used here as the container's main process was not
  confirmed against upstream docs. Verify against
  [Hermes's own documentation](https://github.com/nousresearch/hermes-agent) before relying on it.
