# Deploying to AWS EKS

Example for running either image variant (FR-016) as a Pod in a swarm owner's own EKS cluster,
configurable to a target Account, Cluster, and Namespace (FR-008). This product does not automate
this deployment — the swarm owner provisions the surrounding Kubernetes objects using this as a
starting example, not a Helm chart this product ships.

## Persistent storage (FR-024)

Mount a `PersistentVolumeClaim` at `/data`, backed by whatever storage class the swarm owner's
cluster provides (e.g. EFS CSI driver, for consistency with the ECS Fargate example's use of EFS).

## Credentials (FR-028)

Use the AWS Secrets Store CSI Driver (or External Secrets Operator) to project Secrets Manager
secrets as environment variables in the Pod spec, mapped to the variable names used in
`instance.yaml`'s `*_ref` fields — see `credentials-and-secrets.md`'s AWS section for the default
path convention (`/agents/${AGENT_ID}/*`).

## Image

Pull from GHCR: `ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` or
`.../paperclip:latest` (FR-030). Requires an `imagePullSecret` in the target namespace if the
package is private.

## Updating (FR-023)

Update the Deployment/Pod spec's image reference to the new tag/digest; the existing
`PersistentVolumeClaim` (and its `/data/instance.yaml`) is reused unchanged (FR-026).
