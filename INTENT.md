# Intent

## Purpose
Configure an agentic software-engineering team — a fleet of AI coding agents organized under
an orchestration/collaboration layer — that can run either locally or in AWS.

## Goals
- Configure a multi-agent software engineering team: distinct agent personas (e.g. Security
  Auditor, Database Architect, QA Automation) coordinated by an orchestration plane (Paperclip AI).
- Support two deployment targets: a local runtime and a hosted AWS runtime.
- Provide enterprise-grade isolation, fine-grained access governance, persistent agent memory,
  and human-in-the-loop developer collaboration, as drafted for the AWS target in
  `initial-context.md`.

## Open questions
- **Local-mode architecture is not yet designed.** `initial-context.md` and
  `documentation/technical-architecture.md` currently describe only the AWS deployment. What the
  local runtime looks like, and what (if anything) is shared between local and AWS modes, is
  unresolved.

## How this file is used
INTENT.md captures *why* this project exists and what it's aiming at — distinct from *how*
(`documentation/technical-architecture.md`) and *what's built* (`documentation/product-summary.md`,
`documentation/product-details.md`). Update it when goals or scope change, not when implementation
details change.
