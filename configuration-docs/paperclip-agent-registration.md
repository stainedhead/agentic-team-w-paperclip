# Registering an Agent with Paperclip

An instance's container configuration and its **identity in Paperclip** are two separate things you
have to set up, and they have to agree. This page covers the Paperclip side.

> **Where the boundary sits:** Paperclip is a third-party product with its own documentation
> ([docs.paperclip.ing](https://docs.paperclip.ing/reference/api/overview/)) — the authority on its
> registration flow is Paperclip, not this page. What follows is what this project's images assume
> about it, and the one field that must match on both sides.

## The one thing that must match

| Paperclip side | Instance side |
|---|---|
| The agent's id in Paperclip's roster | `paperclip.agent_id` in `/data/instance.yaml` |

The instance's work-pull job runs `paperclipai agent inbox-mine --user-id <paperclip.agent_id>`. If
that id does not correspond to a registered agent, the poll returns nothing and the instance sits
idle — it does not error in a way that is obvious from the outside. If `paperclip.agent_id` is left
empty the container says so in its log at startup and skips registering the poll job entirely.

## Registering

Two routes, both Paperclip's own:

**The UI** — Paperclip's "New Agent" form is the primary path: name, title, role, reporting chain,
and adapter/runtime. This is usually the easier route because it is also where you place the agent
in the org chart.

**The CLI** — for scripted setup:

```sh
# Registers immediately.
paperclipai agent create --company-id <company-id> --payload-json '{ ... }'

# Submits to an approval queue instead.
paperclipai agent hire --company-id <company-id> --payload-json '{ ... }'
```

Check `paperclipai agent create --help` for the current payload shape rather than trusting an
example here — it belongs to Paperclip and can change between releases.

## Getting the Agent API key

Registration is where you obtain the instance's **Agent API key** — a long-lived credential
intended for exactly this out-of-band/CLI use (Paperclip also issues short-lived run JWTs for
in-heartbeat calls and session cookies for the UI; neither is what an instance needs).

> **Honest gap:** exactly where that key is surfaced — which screen, or which field of the CLI's
> response — is Paperclip's own UI/API surface and is not documented here, because it is not ours to
> pin down and would go stale. Expect to find it in the agent's detail view after creating it, or in
> the `agent create` response. If it is not obvious, Paperclip's
> [API documentation](https://docs.paperclip.ing/reference/api/overview/) is the authority, not this
> page.

Supply it to the instance as a credential like any other — never in `instance.yaml` itself:

```yaml
# /data/instance.yaml
paperclip:
  agent_id: reviewer-01
  api_key_ref: PAPERCLIP_AGENT_API_KEY   # a NAME; the value lives in .env / Secrets Manager
```

See [credentials-and-secrets.md](credentials-and-secrets.md).

## Personas and roles

`personas` in `instance.yaml` declares which personas *that container* is prepared to act as. The
role and reporting chain that Paperclip assigns the agent is separate, and set on the Paperclip
side. Keeping them aligned is your call as swarm owner — this product does not reconcile them, and
nothing stops you from registering an agent as an Architect while its instance declares `[Reviewer]`.

A single instance can carry several personas; how you distribute them across instances is a
team-design decision. See [`templates/instance/`](../templates/instance/) for both shapes.

## Order of operations

Registration and container startup are independent, so either order works:

1. Register the agent in Paperclip and note its id and API key.
2. Start the instance once so it writes a default `/data/instance.yaml`.
3. Fill in `paperclip.agent_id` and `paperclip.api_key_ref`, add the key to your `.env` or secret
   store, and restart the container.

On restart the bootstrap registers the Hermes cron job that pulls work. It logs the schedule it
registered, and guards against creating a duplicate job if one already exists.

## Checking it worked

```sh
# The container runs as the non-root `agent` user, so Hermes's state lives under /home/agent.
container exec <agent-name> cat /home/agent/.hermes/cron/jobs.json   # the poll job, as Hermes stored it
container logs <agent-name>                                          # bootstrap output + Hermes's own log
```

The startup log reports the personas, model host and agent id it resolved from `instance.yaml`, so a
mismatch between what you edited and what the container actually read is visible there. Hermes may
also offer a `hermes cron list`-style command — check its own CLI help; the jobs file above is the
path this project confirmed directly.

## Jira and GitHub

Work can reach Paperclip from Jira and GitHub through **Paperclip's own connectors**, configured in
Paperclip, not here — Jira via OAuth (Atlassian Cloud only), GitHub via its Issues sync. Agents can
then read extra detail from, and write back to, those systems directly, while still reporting
progress to Paperclip as the system of record. For the credential an agent needs to talk to GitHub
itself, see [github-cli-and-pat.md](github-cli-and-pat.md).
