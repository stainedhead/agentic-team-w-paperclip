# Research: Agentic Team with Paperclip

**Created:** 2026-09-27
**Source PRD:** `specs/260927-agentic-team-w-paperclip/agentic-team-w-paperclip-PRD.md`

## Research Questions

1. **Hermes, OMP, and OpenCode CLI installation/config surface** — what are the actual install
   methods, config file formats, and cron/scheduling mechanisms for these three harnesses? FR-004
   and FR-019/FR-021 depend on Hermes having a built-in cron capability with a sensible default —
   what does that configuration actually look like?
2. **Paperclip's actual API/config surface** — FR-011/FR-018/FR-019 assume Paperclip exposes a
   way to register an agent (identity + persona/role) into its roster and a way for a harness to
   poll it for assignments. What does that API/config actually look like today?
3. **AWS Secrets Manager path convention** — FR-028 requires AWS-deployed instances to source
   credentials from Secrets Manager. `documentation/architectual-decisions-record.md` (ADR-0002)
   already scopes credentials by path per agent (`/agents/${AGENT_ID}/*`) for filesystem/IAM
   isolation — should model-host and auth-identity credentials reuse that same path convention,
   or does model-host credential storage need its own scheme?
4. **macOS `Container` persistent storage mechanism** — FR-024 requires persistent storage
   surviving restarts/updates for local deployments. What does the native macOS `Container`
   runtime offer for this (bind mount, named volume, other), and what is the minimal working
   recipe worth documenting per the narrowed local-mode open question in the PRD?
5. **Implementation stack for CI/CD and config schema** — the PRD specifies no language/tooling
   choice. FR-030/FR-031 need a CI/CD platform (assume GitHub Actions, given GHCR + GitHub
   Releases as targets) and some format for per-instance configuration/metadata (FR-017,
   FR-024-026) — what's the simplest schema that satisfies "swarm owner configures a harness
   instance directly" without inventing unnecessary tooling?

## Industry Standards

`[TBD]`

## Existing Implementations

`[TBD — investigate Hermes, OMP, OpenCode CLI, and Paperclip AI's own documentation/repos if
available, rather than assuming behavior.]`

## API Documentation

`[TBD — see research questions 1 and 2.]`

## Best Practices

`[TBD — GHCR publishing and GitHub Releases automation conventions once the CI/CD platform is
confirmed.]`

## Open Questions

- Carried from the PRD: local-mode persistent storage recipe for the macOS `Container` runtime
  (narrowed scope — see PRD Open Questions and research question 4 above).

## References

- `agentic-team-w-paperclip-PRD.md` (this spec directory)
- `documentation/technical-architecture.md`
- `documentation/architectual-decisions-record.md`
- `configuration-docs/credentials-and-secrets.md`
