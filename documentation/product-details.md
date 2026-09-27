# Product Details

> Scope note: this describes what has actually been built. The original
> [../initial-context.md](../initial-context.md) AWS enterprise draft (Okta SSO, worktree review
> dashboard, budget/token-burn UI) was the starting *intent*, not the deliverable — see ADR-0010.

## Components

### The two container images

Built and published to GHCR by this product's CI/CD.

- **Harness-only image** (`images/harness/`) — installs
  [Hermes](https://github.com/nousresearch/hermes-agent) (Nous Research Hermes Agent),
  [OMP](https://github.com/can1357/oh-my-pi) (oh-my-pi) and
  [OpenCode CLI](https://opencode.ai/docs/cli/), plus the GitHub CLI and `yq`. Runs Hermes on startup
  as the always-on harness. This is the normal fleet instance.
- **Harness-plus-Paperclip image** (`images/paperclip/`) — built `FROM` the harness image (ADR-0006),
  adds [Paperclip](https://paperclip.ing/), runs both on startup under a small supervisor that forwards
  shutdown signals to each (ADR-0013).

Both run as a non-root user (uid/gid 1000) and are published for `linux/amd64` and `linux/arm64`.

### Personas

CTO, Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian. An instance declares
which of them it is prepared to act as via `personas` in `/data/instance.yaml`; one instance can carry
several. Distributing personas across instances is the swarm owner's team design — this product
prescribes no org chart, and the persona list is a configurable value rather than encoded behavior.

### The upstream tools

All four are real, independently maintained third-party products, not built here:

| Tool | Role | Links |
|---|---|---|
| Hermes | Always-on harness; its built-in cron scheduler pulls work. Can orchestrate OMP/OpenCode behind the scenes. | [repo](https://github.com/nousresearch/hermes-agent) · [cron docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) |
| OMP (oh-my-pi) | Coding harness | [repo](https://github.com/can1357/oh-my-pi) · [CLI docs](https://omp.sh/docs/cli) |
| OpenCode CLI | Coding harness, supports headless use | [site](https://opencode.ai) · [CLI docs](https://opencode.ai/docs/cli/) |
| Paperclip | Orchestration/collaboration plane; agent roster; system of record for work | [site](https://paperclip.ing/) · [docs](https://docs.paperclip.ing/reference/api/overview/) · [repo](https://github.com/paperclipai/paperclip) |

All three harnesses are installed in every image so that *which* ones an instance uses stays a
configuration decision rather than an image rebuild.

## How an instance gets its work

1. The swarm owner configures the instance (`/data/instance.yaml`: personas, model host, credential
   references) and **separately** registers its agent identity and role with Paperclip. The
   `paperclip.agent_id` field must match that registration.
2. On startup the instance's bootstrap resolves the configuration and registers a Hermes cron job —
   by default every 5 minutes, configurable per instance via `paperclip.poll_schedule` (ADR-0014) —
   that runs `paperclipai agent inbox-mine` to retrieve assigned work. **Pull, not push:** Paperclip
   never initiates a connection into an instance.
3. Agents can query Jira or GitHub directly for detail on an assigned item, and write back to them
   (closing a Jira ticket, opening a PR) — while always also updating Paperclip, which remains the
   system of record.

Work reaches Paperclip from Jira and GitHub through **Paperclip's own connectors**, configured in
Paperclip rather than here.

## Configuration and credentials

A single `/data/instance.yaml` per instance is this product's own configuration surface (ADR-0008), on
a persistent volume the swarm owner provides. It is bootstrapped from a default template on first start
and reused thereafter — an image update never resets an instance's configuration.

Credentials are never in that file: it holds only `*_ref` fields **naming** the variable that carries
each value, resolved at startup against the container's own environment (a `.env` file locally, AWS
Secrets Manager in AWS). The bootstrap resolves every field into a generated env file and exports the
results, so the same `instance.yaml` works unchanged on every deployment target (ADR-0011).

See [credentials-and-secrets.md](../configuration-docs/credentials-and-secrets.md) and the
[configuration reference](../user-docs/configuration-reference.md).

## Deployment

Documented and templated, not automated: example recipes and copy-pasteable artifacts exist for macOS
`container`, ECS Fargate and EKS in [configuration-docs/](../configuration-docs/) and
[templates/](../templates/). Running the deployment is the swarm owner's responsibility.

## What this product explicitly does not do

- **Deploy anything.** It builds, publishes and documents; the swarm owner deploys.
- **Configure a specific team.** Personas, instance counts and reporting structure are the swarm
  owner's design.
- **Implement or override the four tools' runtime behavior** — retries, credential-failure handling,
  scheduling internals, collaboration semantics. Each tool owns its own.
- **Provide real-time monitoring of agent internals, or billing/chargeback.**
- **Provide enterprise identity, governance or service discovery.** Sections 1-6 of
  [technical-architecture.md](technical-architecture.md) record that as target design; none of it is
  built here.

## Verification status

Both images build and pass runtime verification in CI's `smoke-build` job — they run as the non-root
user, keep every tool on `PATH` after the privilege drop, and bootstrap `instance.yaml` correctly. See
the Status section of [../README.md](../README.md) for the assertion output and for what is still
unverified: volume permissions against a real mount, the entrypoints running as PID 1, and
`linux/arm64`.

See [technical-architecture.md](technical-architecture.md) for the technical design and
[architectual-decisions-record.md](architectual-decisions-record.md) for the reasoning behind these
choices.
