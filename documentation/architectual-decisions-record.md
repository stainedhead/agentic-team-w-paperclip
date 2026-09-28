# Architectural Decision Record

Append-only log. To change a decision, add a new entry that supersedes the old one — never edit
a past entry in place.

> **Read ADR-0010 before ADR-0001 through ADR-0005.** Those five entries were inherited from
> `../initial-context.md` and describe a **target AWS enterprise design that this project does not
> build** (ECS services per persona, IAM/EFS isolation, Okta at ingress, Aurora state, CDK
> factory). They are kept because they record real decisions about the eventual design, but nothing
> in this repository implements them. ADR-0010 onwards describe what is actually built.

| ADR | Subject | Applies to |
|---|---|---|
| 0001–0005 | ECS/Graviton fleet, IAM+EFS isolation, Okta ingress, Aurora state, CDK factory | Target design — **not built here** |
| 0006–0009 | Image lineage, work-poll mechanism, `instance.yaml`, secret paths | What is built |
| 0010–0015 | Scope boundary, config resolution, build context, process supervision, poll schedule, Node/Paperclip install | What is built |

## ADR-0001: Deploy the worker fleet as long-running ECS Fargate tasks on ARM64 (Graviton)
- **Status**: Accepted (2026-09-27)
- **Context**: Need isolated, long-running compute per agent persona.
- **Decision**: Each agent persona runs as a distinct long-running ECS Fargate service, built
  from a common base container image, on Linux ARM64 (Graviton).
- **Consequences**: Lower cost profile than x86; requires ARM64-compatible toolchain images.

## ADR-0002: Isolate personas by IAM task role + EFS Access Point, not shared credentials/filesystem
- **Status**: Accepted (2026-09-27)
- **Context**: Agents execute arbitrary code (e.g. during testing) against real infrastructure; a
  compromised or misbehaving agent should have a bounded blast radius.
- **Decision**: Every worker task gets its own IAM task role; filesystem access goes through a
  dedicated EFS Access Point per persona (own root directory, enforced POSIX UID/GID 1000:1000,
  permission mask 0750); Secrets Manager credentials are scoped by path per agent.
- **Consequences**: The QA agent cannot reach production data stores; the DB Architect agent
  cannot modify IAM; no path traversal between persona directories.

## ADR-0003: Enforce identity (Okta) at the AWS ingress boundary, not inside Paperclip
- **Status**: Accepted (2026-09-27)
- **Context**: Paperclip AI has no native enterprise SSO / Okta SAML/OIDC handling.
- **Decision**: Offload identity enforcement to the ingress layer — ALB with a native Okta OIDC
  Authenticate action for browser traffic; API Gateway with an Okta JWT Authorizer for
  programmatic traffic. Verified claims are injected upstream to Paperclip.
- **Consequences**: Paperclip trusts the ingress layer's claims rather than performing its own
  auth; ingress configuration becomes security-critical.

## ADR-0004: Use Aurora Serverless v2 (PostgreSQL) as the orchestrator's state store
- **Status**: Accepted (2026-09-27)
- **Context**: The orchestration plane needs a durable store for the task graph, budget caps,
  execution locks, and event logs.
- **Decision**: Back the Paperclip orchestrator with Aurora Serverless v2 (PostgreSQL).
- **Consequences**: Serverless scaling of the state store; cost shared/amortized across the fleet.

## ADR-0005: Build worker deployments with a CDK factory pattern from a single base image
- **Status**: Accepted (2026-09-27)
- **Context**: Multiple worker personas need consistent, repeatable deployment with
  persona-specific isolation config layered on top.
- **Decision**: Use a single standardized base container image (Hermes, OMP, OpenCode CLI, Git,
  language SDKs) and generate each persona's ECS service via a CDK factory ("Model 3").
- **Consequences**: Consistent runtime across personas; persona differences are expressed as
  factory parameters (IAM role, EFS access point, secrets path) rather than divergent images.

## ADR-0006: Build the harness+Paperclip image FROM the harness-only image
- **Status**: Accepted (2026-09-27)
- **Context**: The product ships two container image variants — harness-only (Hermes, OMP,
  OpenCode CLI) and harness+Paperclip. Both need the same harness-layer tooling.
- **Decision**: The harness+Paperclip image's Dockerfile (`images/paperclip/Dockerfile`) uses
  `FROM ${BASE_IMAGE}` with the harness-only image as the default base, adding only Paperclip and
  overriding the entrypoint to run both Hermes and Paperclip.
- **Consequences**: Harness-layer changes (tool versions, `yq`/`gh` install, bootstrap logic)
  propagate to both variants automatically instead of drifting apart across two independently
  maintained Dockerfiles. CI pins the FROM relationship by digest (not a mutable tag) to avoid a
  race between the two builds landing on the registry — see
  `.github/workflows/build-and-publish.yml`.

## ADR-0007: Implement the Paperclip work-poll as a Hermes cron job calling Paperclip's own CLI
- **Status**: Accepted (2026-09-27)
- **Context**: FR-019 requires a harness instance to retrieve its assigned work by polling
  Paperclip on a recurring schedule. Paperclip's own platform actually supports two mechanisms:
  a server-initiated heartbeat "wakeup" API, and a pull-style CLI (`agent inbox`/`inbox-mine`).
- **Decision**: Use Hermes's built-in cron scheduler to run `paperclipai agent inbox-mine
  --user-id <id> --status todo,in_progress` on a recurring schedule (default every 5 minutes),
  rather than building custom polling code or wiring up Paperclip's push-based wakeup API.
- **Consequences**: No custom scheduler/poll logic to build or maintain — the mechanism is
  entirely "configure two existing tools to call each other." Retry/failure behavior on a missed
  poll is Hermes's/Paperclip's own concern (see `spec.md`'s Edge Case Handling scope boundary),
  not something this product implements.

## ADR-0008: A single `instance.yaml` file is this product's own configuration surface
- **Status**: Accepted (2026-09-27)
- **Context**: FR-017 requires a swarm owner to configure persona assignment, model-host
  selection, and identity references per harness instance. None of Hermes, OMP, OpenCode CLI, or
  Paperclip has a config format for this — it's specific to this product.
- **Decision**: Introduce `/data/instance.yaml` (on the same persistent-storage volume as
  FR-024) as the single file for this product's own settings, with `*_ref` fields naming (never
  containing) credentials. The entrypoint bootstrap applies its values into each tool's own
  config on startup, rather than duplicating each tool's full native config surface.
- **Consequences**: One clear place a swarm owner edits for this product's own settings; a
  slightly more complex entrypoint (translates `instance.yaml` into Hermes/OMP/OpenCode's native
  config on every start) in exchange for not inventing a broader configuration system.

## ADR-0009: Extend ADR-0002's per-agent Secrets Manager path scheme to all newly-identified credentials
- **Status**: Accepted (2026-09-27)
- **Context**: This product's credential set grew beyond ADR-0002's original scope (model-host
  API keys, a Paperclip Agent API key, a GitHub PAT).
- **Decision**: Reuse ADR-0002's `/agents/${AGENT_ID}/*` path convention for all of them (e.g.
  `/agents/${AGENT_ID}/model-host-api-key`, `/agents/${AGENT_ID}/paperclip-agent-api-key`,
  `/agents/${AGENT_ID}/github-pat`) rather than inventing a separate scheme per credential type.
- **Consequences**: One consistent convention across the whole credential set; a swarm owner who
  wants a shared (non-per-agent) credential, such as one model-host key across agents, deviates
  from this default deliberately rather than the product forcing per-agent secrets everywhere.

## ADR-0010: This product's deliverable is images + templates + documentation, not a deployed team
- **Status**: Accepted (2026-09-27)
- **Context**: ADR-0001–0005, inherited from `../initial-context.md`, describe a full AWS
  enterprise platform. Read without qualification they imply this repository deploys ECS services,
  terminates Okta at an ALB, and runs an Aurora state store. It does none of that. The project's
  actual purpose is narrower and needs to be stated as a decision rather than left implicit in
  prose: provide the **baseline** a swarm owner builds their own solution from.
- **Decision**: The deliverable is (a) two container images published to GHCR, (b) a single
  `instance.yaml` configuration surface, (c) copy-pasteable configuration and deployment templates,
  (d) CI/CD that builds, publishes and releases the images, and (e) the documentation covering all
  of it. Deployment, team design, agent registration and environment-specific identity/networking/
  governance are the swarm owner's responsibility. Agent behavior, scheduling internals and
  failure/retry semantics are the upstream tools' responsibility (Hermes, OMP, OpenCode,
  Paperclip). ADR-0001–0005 are retained as recorded target design, explicitly **not implemented**.
- **Consequences**: A clear, defensible boundary — the project is not accountable for the behavior
  of four third-party tools, nor for any swarm owner's environment. The cost is that a reader
  looking for a turnkey agent team will not find one here; README.md and INTENT.md now say so in
  their first paragraphs. The enterprise design in `technical-architecture.md` sections 1-6 remains
  available as a starting point should a future feature pick it up.

## ADR-0011: Resolve `instance.yaml` into one generated env file, not into each tool's native config
- **Status**: Accepted (2026-09-27) — supersedes the *mechanism* described in ADR-0008 (its
  decision to have a single `instance.yaml` stands unchanged)
- **Context**: ADR-0008 stated the bootstrap "applies its values into each tool's own config on
  startup". In practice the implementation only ever wrote a `~/.hermes/.env` file, and read just
  three of the file's fields — `personas` and both `model_host.*` fields were inert, so two of the
  four documented configuration sections did nothing. Closing the gap the other way (writing into
  Hermes's, OMP's and OpenCode's native config files) would mean encoding three config schemas that
  this project does not own, has not verified, and that can change under it at any upstream release.
- **Decision**: The bootstrap resolves every `instance.yaml` field into a single generated
  environment file (`~/.hermes/.env`) — `*_ref` fields dereferenced against the container's own
  environment, scalar fields exported directly (`AGENT_PERSONAS`, `MODEL_HOST_PROVIDER`,
  `MODEL_HOST_API_KEY`, `PAPERCLIP_AGENT_ID`, …). Tools and the swarm owner's own prompts/skills
  consume those variables. The file is regenerated on every start and marked as generated.
- **Consequences**: Every documented field now has an observable effect, and the project never
  parses or rewrites a third-party config schema it does not control. A swarm owner who needs a
  value inside a tool's *native* config places it there themselves, referencing these variables.

## ADR-0012: Each image's Docker build context is its own directory under `images/`
- **Status**: Accepted (2026-09-27)
- **Context**: Both Dockerfiles `COPY` their sidecar files by bare filename
  (`COPY instance.default.yaml harness-bootstrap.sh entrypoint.sh ./`). CI originally passed
  `context: .` (the repo root), where those filenames do not exist — the build failed at the first
  `COPY`. Two fixes were possible: prefix every `COPY` source with `images/<variant>/` and keep the
  root context, or narrow the context to the image's own directory.
- **Decision**: Narrow the context — `context: images/harness` and `context: images/paperclip`.
- **Consequences**: `docker build images/harness` locally behaves identically to CI, which is the
  property that makes the images reproducible for a swarm owner building their own variant. Build
  contexts stay minimal (no repo docs or specs shipped into the daemon). The constraint is that a
  Dockerfile cannot `COPY` anything from outside its own directory; if shared build-time files are
  ever needed, this decision must be revisited rather than worked around with a symlink.

## ADR-0013: Supervise the two-process container in the entrypoint with signal forwarding
- **Status**: Accepted (2026-09-27)
- **Context**: The harness+Paperclip image must run two processes. The original entrypoint started
  Paperclip in the background, installed a `trap` to forward `TERM`, then `exec`'d the Hermes
  gateway. `exec` replaces the shell process — which discards its traps — so the forwarding was
  dead code: on container stop, Hermes received `TERM` and Paperclip was killed abruptly with the
  container. Alternatives considered: add a real init (`tini`, `s6-overlay`, `supervisord`).
- **Decision**: Do not `exec`. The entrypoint stays PID 1 as a small supervisor: start both
  children in the background, `trap` `TERM`/`INT` to forward the signal to both and wait for them
  to exit, and treat either child exiting as a reason to shut down the container.
- **Consequences**: Correct signal propagation and orderly shutdown with no extra image
  dependency, and a crashed Paperclip now takes the container down (visible to the orchestrator's
  restart policy) instead of silently disappearing. This is deliberately *not* a restart
  supervisor — a swarm owner wanting in-container restarts should add `s6-overlay` or run the two
  processes as separate containers/tasks; ECS, Kubernetes and `container` all restart on exit,
  which is why exiting is the better default here.

## ADR-0014: The Paperclip poll schedule is an `instance.yaml` field with a default
- **Status**: Accepted (2026-09-27)
- **Context**: The poll interval (ADR-0007) was a constant inside `harness-bootstrap.sh`. The
  configuration reference therefore had to tell swarm owners to edit the image's entrypoint to
  change it — meaning rebuilding the image to alter an operational tuning value, while every other
  instance-level setting was one edit to a file on the persistent volume.
- **Decision**: Add `paperclip.poll_schedule` (a cron expression) to `instance.yaml`, defaulting to
  `*/5 * * * *` when unset or absent, so existing configs keep their current behavior.
- **Consequences**: Interval changes are a config edit plus restart, not an image rebuild. The
  value is passed to `hermes cron create` unvalidated — an invalid cron expression surfaces as a
  Hermes error in the container log, which is consistent with this project's boundary of not
  reimplementing tool-side validation.

## ADR-0015: Install Node.js explicitly and install Paperclip from npm, not via `install.sh`
- **Status**: Accepted (2026-09-27)
- **Context**: Both facts here came from the first real `docker build` of these images, via the new
  `smoke-build` CI job; neither was discoverable by review:
  1. **Paperclip does not bundle Node.js.** The installer reported `[paperclip] Node.js was not
     found` on an image without it. Its own script declares `MIN_NODE_MAJOR=20` and
     `DEFAULT_NODE_MAJOR=22`.
  2. **`https://paperclip.ing/install.sh` cannot run in a container image.** It sets `NO_PROMPT=1`
     whenever stdin/stdout is not a TTY — always true during a build — and then delegates to
     `npx --yes paperclipai@latest install --no-prompt`. The published `paperclipai` package rejects
     that flag: `error: unknown option '--no-prompt'`. The script is unusable non-interactively
     regardless of Node, and this is an upstream incompatibility that this project cannot fix.
- **Decision**: Install Node.js explicitly in `images/paperclip/Dockerfile` from NodeSource — the
  same source Paperclip's own script uses on Debian — pinned to major version 22 via
  `ARG NODE_MAJOR=22`, then install the CLI directly with `npm install -g paperclipai@latest`.
  Major 22 rather than 20 or 24 because it is what upstream itself installs and therefore tests
  against; 24 also satisfies the declared minimum and is a one-flag override.
- **Consequences**: The image builds non-interactively and deterministically, and `npx paperclipai`
  resolves against a baked-in global install rather than fetching from the network on first boot.
  The cost is a deliberate deviation from Paperclip's documented install path: this project now
  tracks the npm package directly, so a future change to what `install.sh` does *besides* installing
  Node and the package would not be picked up automatically. Revisit if upstream fixes the
  `--no-prompt` incompatibility.

## Open (not decided)
- **Full local networking/service-discovery/identity-store design** equivalent to the AWS
  architecture in sections 1-6 — narrowed out of scope for this product (the swarm owner's concern
  for their own local environment); see [INTENT.md](../INTENT.md).
- **The literal foreground invocation for the Hermes gateway as PID 1.** `hermes gateway run
  --foreground` is used; research confirmed `hermes gateway install` sets up a *service*, and the
  foreground form was not confirmed against upstream docs. The `smoke-build` job deliberately does
  not exercise it (it sources the bootstrap instead of running the entrypoint, which would block),
  so this remains the main unverified runtime assumption.
