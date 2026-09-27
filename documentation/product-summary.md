# Product Summary

An internal, multi-agent software engineering platform: a fleet of autonomous dev-agent "workers,"
each running a distinct persona (e.g. Security Auditor, Database Architect, QA Automation),
coordinated by a central orchestration and collaboration layer (Paperclip AI). Developers interact
with the fleet through a dashboard and CLI, assigning work and reviewing agent output.

The platform is intended to run either locally or in AWS. AWS is the only target designed so far
(see [technical-architecture.md](technical-architecture.md)); local-mode design is an open item
(see [INTENT.md](../INTENT.md)).
