# Configuring GitHub CLI (`gh`) and a Personal Access Token

The images ship the [GitHub CLI](https://cli.github.com/) so agents can read issues, open pull
requests and interact with GitHub Projects. This page covers the credential it needs.

> **Scope:** this product configures the credential. It does not build or guarantee a specific
> GitHub Projects/Issues *integration*. Work can reach Paperclip through Paperclip's own GitHub
> connector (which syncs Issues), or an agent can use `gh` directly — either way the token below is
> what authorizes it.

## 1. Create the token

A GitHub Personal Access Token, either:

- a **fine-grained PAT** scoped to the repositories or organization your agents may touch — the
  better choice where it suffices; or
- a **classic PAT** with `repo` and `project` scopes, which is required for the Projects v2 GraphQL
  API. Re-verify that against
  [GitHub's own documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  before assuming it still holds.

Give each agent its own token if you want per-agent attribution in commit and PR history — a bot
account per persona is the usual pattern.

## 2. Supply it to the instance

Like every credential here, the token's **value** never goes in `instance.yaml` — only the name of
the variable holding it:

```yaml
# /data/instance.yaml
identity:
  github_bot_account_ref: GITHUB_PAT
```

**Locally**, in the instance's `.env` (see [`templates/env/.env.example`](../templates/env/.env.example)):

```
GITHUB_PAT=<your PAT>
```

**In AWS**, as a Secrets Manager secret injected under that same variable name — the default path
convention is `/agents/<agent-id>/github-pat`. See
[credentials-and-secrets.md](credentials-and-secrets.md).

## 3. How it reaches `gh`

The startup bootstrap resolves `identity.github_bot_account_ref`, and **exports the resolved value
as `GITHUB_TOKEN`** into the environment that Hermes and everything Hermes spawns inherits. `gh`
reads `GITHUB_TOKEN` natively, so it is authenticated with no `gh auth login` step — and this works
whatever you named the underlying variable.

Two consequences worth knowing:

- You do not need to name your variable `GITHUB_TOKEN`. `GITHUB_PAT`, `BOT_TOKEN`, anything — the
  `*_ref` indirection handles it.
- Because it is an environment token, `gh auth login` inside the container would *conflict* with it.
  Don't; the token is already in effect.

## 4. Verify

Inside a running container:

```sh
container exec <agent-name> gh auth status
```

That should report an authenticated session and the token's scopes. If instead it reports no
authentication, check the startup log:

```sh
container logs <agent-name> | grep -i github
```

A `WARNING: identity.github_bot_account_ref references 'X', but no such variable is set` line means
the name in `instance.yaml` and the name in your `.env`/secret mapping disagree — the single most
common cause. The bootstrap deliberately warns instead of failing, so the container still starts
with its other credentials working.
