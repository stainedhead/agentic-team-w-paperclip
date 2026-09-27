# Research: Agentic Team with Paperclip

**Created:** 2026-09-27
**Source PRD:** `specs/260927-agentic-team-w-paperclip/agentic-team-w-paperclip-PRD.md`

## Research Questions

1. ~~**Hermes, OMP, and OpenCode CLI installation/config surface**~~ — **Answered 2026-09-27**,
   see Existing Implementations below.
2. ~~**Paperclip's actual API/config surface**~~ — **Answered 2026-09-27**, see Existing
   Implementations and API Documentation below.
3. **AWS Secrets Manager path convention** — still open. `documentation/architectual-decisions-record.md`
   (ADR-0002) scopes credentials by path per agent (`/agents/${AGENT_ID}/*`) for filesystem/IAM
   isolation — should model-host, auth-identity, and Paperclip Agent API key credentials reuse
   that same path convention, or does each need its own scheme?
4. **macOS `Container` persistent storage mechanism** — still open. What does the native macOS
   `Container` runtime offer for a persistent volume (bind mount, named volume, other), and what
   is the minimal working recipe worth documenting per the narrowed local-mode open question in
   the PRD?
5. **CI/CD platform** — **Answered 2026-09-27** (GitHub Actions + `docker/build-push-action` to
   GHCR, standard pattern confirmed current). **Instance config schema — still open**: the
   harness instance's own configuration file (persona assignment, model-host selection — FR-017)
   isn't any of the four tools' own config format; its shape and location still need deciding
   (see `architecture.md`).

## Industry Standards

GitHub Actions building a Docker image, publishing to GHCR, and cutting a GitHub Release on tag
push is standard, current practice as of 2026-09-27: `docker/login-action` +
`docker/build-push-action`, `GITHUB_TOKEN` with `packages: write` permission, release triggered
on the `release` event (`published`) or a tag push, release notes via `softprops/action-gh-release`
or `gh release create`. Source: [GitHub Docs — Publishing Docker images](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images).

## Existing Implementations

Confirmed 2026-09-27 via web research (all four tools are real, current products — see PRD's
"Tool reality" clarification):

- **Hermes** = Nous Research's **Hermes Agent**.
  [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron) ·
  [github.com/NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)
  - Install: `hermes gateway install` (user service) or `sudo hermes gateway install --system`
    (Linux boot service).
  - Config: YAML at `~/.hermes/config.yaml`; secrets at `~/.hermes/.env`.
  - **Cron confirmed real**: built-in scheduler, gateway ticks every 60s and runs due jobs in
    isolated sessions. Create via chat (`/cron add "schedule" "task"`), CLI (`hermes cron create
    "schedule" "prompt"`), or natural language. Jobs stored as JSON at `~/.hermes/cron/jobs.json`;
    support cron expressions, intervals, natural-language schedules, one-shot delays. Jobs can run
    in `no_agent` mode as a plain shell script with stdout delivered verbatim (no LLM) — this is
    the likely mechanism for FR-019's "poll Paperclip" job.
  - **Subordinate-process orchestration confirmed, but generic**: cron/agent sessions have
    `terminal`, `execute_code`, `read_file`, `write_file` tools; a kanban dispatcher sweeps task
    boards and spawns worker agent sessions. It *can* shell out to OpenCode CLI/OMP, but there's
    no named "invoke OpenCode" integration — it's general subprocess/tool access, same as any
    other shell command a cron job could run.
  - **Name collision note**: "Hermes" collides with Meta's Hermes JS engine and various unrelated
    messaging libraries. Confirmed with the user 2026-09-27 that Nous Research's Hermes Agent is
    the intended tool.

- **OMP** = **oh-my-pi** (Stencil Labs). [omp.sh/docs/cli](https://omp.sh/docs/cli) ·
  [github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)
  - A terminal coding agent: subagents, plan mode, LSP/DAP, Rust engine, 60+ model providers
    (Anthropic, OpenAI, Gemini, etc.) — not tied to one model.
  - Install: **not confirmed** from the CLI reference page fetched (only `omp update` for
    upgrades was documented there). Verify the actual install command directly from omp.sh before
    writing the Dockerfile step — flagged as a risk in `spec.md`.
  - Config: YAML. Global at `~/.omp/agent/config.yml` or `.yaml`; project-local at
    `.omp/config.yml`; layered built-in defaults → global → project → env vars → runtime flags,
    or via repeatable `--config <file>`.
  - Non-interactive: `-p`/`--print` flag ("process the request without the TUI, then exit"), e.g.
    `omp -p "..."`, `omp -p --mode json "..."`; accepts piped stdin (`git diff | omp -p "Review
    this diff"`).
  - **Name collision note**: ruled out oh-my-posh (prompt theme engine) and open.mp (GTA:SA
    multiplayer mod) as unrelated. Confirmed with the user 2026-09-27 that oh-my-pi is the
    intended tool.

- **OpenCode CLI**. [opencode.ai/docs/cli](https://opencode.ai/docs/cli/)
  - Install: curl script, npm, pnpm, bun, or brew (`upgrade --method` flag records which one was
    used).
  - Config: env vars `OPENCODE_CONFIG` (path), `OPENCODE_CONFIG_DIR`, `OPENCODE_CONFIG_CONTENT`
    (inline JSON); auth/credentials at `~/.local/share/opencode/auth.json`.
  - Non-interactive/automation: `opencode run [message]` executes a prompt and exits (no TUI);
    `opencode serve` starts a headless HTTP API server, and `opencode run --attach
    http://localhost:4096 "..."` reuses it to avoid cold starts; `--format json` for
    machine-readable output, `--auto` to auto-approve permissions.

- **Paperclip**. [paperclip.ing](https://paperclip.ing/) ·
  [docs.paperclip.ing](https://docs.paperclip.ing/reference/api/overview/) · open-source,
  [github.com/paperclipai/paperclip](https://github.com/paperclipai/paperclip)
  - An "AI employees" org-chart orchestration platform — roughly matches the PRD's description.
  - **Registration** (FR-018): primarily a **UI flow** ("New Agent" form: name, title, role,
    reporting chain, adapter/runtime — Claude Code, Codex, etc.). Also a CLI: `paperclipai agent
    create --company-id <id> --payload-json '{...}'` (immediate) vs. `paperclipai agent hire
    --company-id <id> --payload-json '{...}'` (goes to an approval queue). A programmatic
    "hire API" is referenced but wasn't fully documented in what was fetched.
  - **Work retrieval** (FR-019): **heartbeat-driven wake, not simple polling** at the platform's
    core — server-side `POST /api/agents/{id}/wakeup` triggers an on-demand heartbeat run, and
    the agent calls back `POST /api/heartbeat-runs/:runId/complete` when done. But a pull-style
    CLI also exists: `paperclipai agent inbox` / `agent inbox-mine --user-id <id> --status
    todo,in_progress` lists assigned issues — **this is the command a Hermes cron job should call**
    to implement FR-019's "harness polls Paperclip" design.
  - **Auth**: three methods — long-lived **Agent API keys** (`Authorization: Bearer <key>`) for
    out-of-band/CLI/CI use (this is what a Hermes cron job would use), short-lived **run JWTs**
    for in-heartbeat calls, and **session cookies** for the web UI.
  - **Jira**: real connector, OAuth ("Sign in with Jira"), **Atlassian Cloud only** (not Data
    Center/Server); lets agents search/read/comment/update Jira issues, plus Confluence.
  - **GitHub**: real connector syncs **GitHub Issues** (comment-@mention-to-create-task flow).
    **No documentation found for GitHub Projects (the Projects board feature) sync specifically.**
    The user confirmed the product intent is still GitHub Projects (cross-repo, unlike
    single-repo Issues); this spec's actual deliverable is narrowed to `gh` CLI + PAT
    configuration documentation (FR-033) rather than a specific connector guarantee — see
    `spec.md`'s "Scope note: GitHub integration mechanism."

## API Documentation

See Existing Implementations above — Paperclip's endpoints (`POST /api/agents/{id}/wakeup`,
`POST /api/heartbeat-runs/:runId/complete`) and CLI commands (`agent create`, `agent hire`,
`agent inbox`, `agent inbox-mine`) are the concrete integration surface for FR-011/018/019.

## Best Practices

See Industry Standards above.

## Open Questions

- Carried from the PRD: local-mode persistent storage recipe for the macOS `Container` runtime
  (research question 4 above).
- AWS Secrets Manager path convention for the newly-identified credential set: model-host
  credentials, auth-identity credentials, and now also a Paperclip Agent API key and a GitHub PAT
  (research question 3 above).
- Instance configuration file format/location (persona assignment, model-host selection) — the
  one piece of new "architecture" this product needs to define itself, since it doesn't belong to
  any of the four existing tools (research question 5's second half).
- OMP's install method — not confirmed from the docs fetched; verify directly before
  implementation.
- Whether Paperclip's roadmap will add native GitHub Projects support — untracked/out of scope
  for this product either way, per the narrowed FR-033 deliverable.

## References

- `agentic-team-w-paperclip-PRD.md` (this spec directory)
- `documentation/technical-architecture.md`
- `documentation/architectual-decisions-record.md`
- `configuration-docs/credentials-and-secrets.md`
- [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/docs/user-guide/features/cron)
- [github.com/NousResearch/hermes-agent](https://github.com/nousresearch/hermes-agent)
- [omp.sh/docs/cli](https://omp.sh/docs/cli)
- [github.com/can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)
- [opencode.ai/docs/cli](https://opencode.ai/docs/cli/)
- [paperclip.ing](https://paperclip.ing/)
- [docs.paperclip.ing](https://docs.paperclip.ing/reference/api/overview/)
- [github.com/paperclipai/paperclip](https://github.com/paperclipai/paperclip)
- [GitHub Docs — Publishing Docker images](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images)
