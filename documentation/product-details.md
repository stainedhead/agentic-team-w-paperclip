# Product Details

> Scope note: this reflects what has actually been built as of the
> `specs/archive/260927-agentic-team-w-paperclip/` feature (see its `spec.md` for full requirements
> traceability). The original `../initial-context.md` AWS enterprise draft (Okta SSO, worktree
> review dashboard, budget/token-burn UI) was the starting *intent*, not what's built — those
> pieces remain undesigned/unbuilt unless a future feature adds them.

## Components
- **Two container images** (built and published to GHCR by this product's CI/CD):
  - **Harness-only image** (`images/harness/`): installs Hermes (Nous Research Hermes Agent), OMP
    (oh-my-pi), and OpenCode CLI; runs Hermes on startup as the default, always-on harness.
  - **Harness-plus-Paperclip image** (`images/paperclip/`): built `FROM` the harness-only image;
    adds Paperclip; runs both Hermes and Paperclip on startup.
- **Personas**: CTO, Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian. A
  harness instance can be configured to run one or more of them, via `/data/instance.yaml`.
- **Paperclip** — a real, existing orchestration platform (not built by this product) that
  maintains a roster of registered agents and tracks work sourced from Jira and GitHub, alongside
  its own native work items.

## How a harness instance gets its work
- A swarm owner configures a harness instance locally (`/data/instance.yaml`: persona(s),
  model-host selection, credential references) and separately registers that instance's agent
  identity and persona/role with Paperclip.
- Once running, the instance's Hermes cron scheduler polls Paperclip on a recurring schedule
  (`paperclipai agent inbox-mine`) to retrieve assigned work — a pull model, not Paperclip pushing
  to the instance.
- Agents can query Jira or GitHub directly for extra detail on an assigned item, and update those
  systems as part of completing work (e.g. closing a Jira ticket) — but always also update
  Paperclip's own tracking state, which remains the system of record.

## Configuration and credentials
- Locally, credentials are supplied via a `.env` file; in AWS, via AWS Secrets Manager. Either
  way, `/data/instance.yaml` only ever holds a *reference* (an env var / secret name) to a
  credential, never the value itself. See `configuration-docs/credentials-and-secrets.md`.
- See `configuration-docs/github-cli-and-pat.md` for GitHub CLI/PAT configuration, and
  `configuration-docs/deploy-*.md` for per-target deployment examples (macOS `Container`, ECS
  Fargate, EKS) — this product documents deployment, it does not automate it.

## What this product explicitly does not do
- Automate deployment into a swarm owner's environment.
- Implement or override any of the four tools' own runtime behavior (retries, credential-failure
  handling, cron internals) — see `spec.md`'s Edge Case Handling scope boundary in the feature
  spec for the reasoning.
- Provide real-time monitoring of agent internals, or a billing/chargeback system.

See [technical-architecture.md](technical-architecture.md) for the full technical design and
[architectual-decisions-record.md](architectual-decisions-record.md) for the reasoning behind
these choices.
