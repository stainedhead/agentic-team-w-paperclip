# Configuring GitHub CLI (`gh`) and a Personal Access Token

Per `agentic-team-w-paperclip-PRD.md` (FR-033), this is the configuration surface for GitHub
interaction (Projects and/or Issues) regardless of whether it's exercised through Paperclip's own
GitHub connector or an agent using `gh` directly. This product documents the credential setup; it
does not build or guarantee a specific GitHub Projects/Issues integration mechanism (see the
PRD's "Scope note — GitHub integration mechanism").

## What's needed

1. A GitHub Personal Access Token (PAT) — either a fine-grained PAT scoped to the repos/org the
   swarm owner wants agents to access, or a classic PAT with `repo` and `project` scopes if using
   GitHub Projects (classic PATs are required for the Projects v2 GraphQL API as of this
   writing — reverify against GitHub's own docs if this changes).
2. The token supplied to a harness instance the same way as any other credential in this
   product's model (see `credentials-and-secrets.md`): a `.env` var locally, or an AWS Secrets
   Manager secret in AWS. The instance configuration file (`/data/instance.yaml`) references it
   by name via `identity.github_bot_account_ref` — never a raw value.

## Local (`.env`)

```
# .env
GITHUB_PAT=<your PAT>
```

Set `identity.github_bot_account_ref: GITHUB_PAT` in `/data/instance.yaml`.

## AWS (Secrets Manager)

Store the PAT as an AWS Secrets Manager secret and reference it the same way as other AWS
credentials (see `credentials-and-secrets.md`'s AWS section — exact path convention is still
being decided, see `specs/260927-agentic-team-w-paperclip/research.md`).

## Verifying it works

Inside the container:

```
gh auth status
```

should report an authenticated session using the configured token.

# TODO: this document currently describes the credential-configuration side only. Once the
harness image's entrypoint bootstrap logic actually wires `GITHUB_TOKEN`/`gh auth login
--with-token` into the container's `gh` install (see `images/harness/harness-bootstrap.sh`),
update this doc with the concrete verification steps against the real image.
