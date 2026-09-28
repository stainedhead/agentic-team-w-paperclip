# Intent

## Purpose
Provide the **baseline containerized tooling and documentation** that a swarm owner builds an
agentic teammate group from — a packaged, preconfigured container environment carrying the
harnesses an AI agent teammate needs (Hermes, OMP, OpenCode CLI) plus Paperclip as the
orchestration and collaboration plane the team works through.

This project packages and configures existing tools. It does not build harnesses or orchestrators,
and it does not stand up a working team — those are, respectively, the upstream projects' and the
swarm owner's job.

## Goals
- **Ship a reusable baseline.** Two container images, published to GHCR, that come preloaded with
  the harnesses and (in one variant) Paperclip, ready to be configured rather than assembled.
- **Make one instance configurable in one place.** A single `instance.yaml` on persistent storage
  expresses an instance's personas, model host, and credential *references* — so the same image
  and the same config file work unchanged whether the container runs locally or in AWS.
- **Document and template the configuration surface thoroughly.** A swarm owner should be able to
  go from `docker pull` to a registered, working agent by following this repository's docs and
  copying its templates, without reading the images' source.
- **Support the deployment targets swarm owners actually use** — macOS `Container` locally, AWS ECS
  Fargate and EKS — as documented, templated recipes.
- **Keep the model host a configuration choice**, not a build-time one: AWS Bedrock, Ollama Cloud,
  OpenRouter, Anthropic, OpenAI.

## Non-goals
- **Configuring an actual team.** Which personas exist, how many instances run, and how they report
  to each other is the swarm owner's design. This project supports the eight personas (CTO,
  Architect, TechLead, Reviewer, Intern, DevSupport, Researcher, Librarian) as configurable values,
  not as a prescribed org chart.
- **Reimplementing, wrapping or fixing the upstream tools.** Agent reasoning, scheduling internals,
  retry and failure behavior, and collaboration semantics all belong to Hermes, OMP, OpenCode and
  Paperclip.
- **Automating deployment.** This project builds and publishes images and documents how to deploy
  them; running the deployment is the swarm owner's responsibility.
- **Enterprise identity, governance and networking.** The originating draft
  (`initial-context.md`) sketched an AWS enterprise design with Okta at the ingress, Aurora
  Serverless state, and Cloud Map service discovery. That remains recorded **target design, not
  this project's deliverable** — see ADR-0010.
- Real-time monitoring of agent internals, and any billing or chargeback system.

## Scope boundary in one line
> This repository is the *starting point* a swarm owner builds from — images, templates and docs —
> not the finished swarm, and not the tools the swarm is made of.

## How this file is used
INTENT.md captures *why* this project exists and what it is aiming at — distinct from *how*
(`documentation/technical-architecture.md`) and *what's built* (`documentation/product-summary.md`,
`documentation/product-details.md`). Update it when goals or scope change, not when implementation
details change.
