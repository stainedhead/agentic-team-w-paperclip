# Product Summary

**Baseline containerized tooling for an agentic teammate group.**

Two container image variants — a harness-only image ([Hermes](https://github.com/nousresearch/hermes-agent),
[OMP](https://github.com/can1357/oh-my-pi), [OpenCode CLI](https://opencode.ai)) and a
harness-plus-[Paperclip](https://paperclip.ing/) image built from it — that a **swarm owner** deploys
locally (macOS `container`) or in AWS (ECS Fargate, EKS) to run a team of AI agent personas: CTO,
Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian.

Paperclip is the orchestration and collaboration plane: it holds the agent roster, tracks work
(its own items plus synced Jira and GitHub items), and is the system of record agents report back to.
Each harness instance pulls its own assignments on a schedule using Hermes's built-in cron — so work
flows pull-based, and Paperclip never needs to reach into an instance.

## What this product is

It ships the **starting point**, not a finished team:

- the two images, built and published to GHCR;
- a single-file configuration surface per instance (`/data/instance.yaml`);
- copy-pasteable configuration and deployment templates;
- CI/CD that lints, smoke-tests, builds multi-arch and publishes the images;
- the documentation covering all of it.

## What it is not

It does not deploy anything, does not configure a specific team, and does not implement any of the
four tools it packages — those are, respectively, the swarm owner's job, the swarm owner's design
decision, and the upstream projects' job. See [ADR-0010](architectual-decisions-record.md) for the
scope boundary as a recorded decision, and [INTENT.md](../INTENT.md) for why.

## Read next

- [product-details.md](product-details.md) — components, the work-retrieval workflow, and the
  explicit boundaries.
- [technical-architecture.md](technical-architecture.md) — image lineage, the build pipeline, and the
  still-unbuilt target AWS design.
- [../README.md](../README.md) — orientation, diagrams, and links into the user and configuration docs.
