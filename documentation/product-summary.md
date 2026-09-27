# Product Summary

A configuration/build product for an agentic software-engineering platform: two container image
variants — a harness-only image (Hermes, OMP, OpenCode CLI) and a harness-plus-Paperclip image
built from it — that a "swarm owner" deploys, either locally (macOS `Container`) or in AWS (ECS
Fargate, EKS), to run a team of AI agent personas (CTO, Architect, TechLead, Reviewer, Intern,
DevSupport, Researcher, Librarian). Paperclip (a real, existing orchestration platform) tracks
work sourced from Jira and GitHub, and harness instances retrieve their assignments by polling it
on a recurring schedule.

This product builds and publishes the images (to GHCR) and documents how to configure and deploy
them; it does not perform deployment itself — that's the swarm owner's responsibility. See
[product-details.md](product-details.md) for the full component/workflow breakdown and
[technical-architecture.md](technical-architecture.md) for the build/deployment architecture.
