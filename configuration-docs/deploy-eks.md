# Deploying to AWS EKS

Running an instance as a Pod in your own EKS cluster, targeting a configurable account, cluster and
namespace. An example to adapt — you provision the surrounding Kubernetes objects; this product does
not ship a Helm chart.

Ready-to-edit manifests: [`templates/aws-eks/deployment.yaml`](../templates/aws-eks/deployment.yaml)
(PersistentVolumeClaim + SecretProviderClass + Deployment).

## Shape of a deployment

One Deployment per agent instance:

| Setting | Value | Why |
|---|---|---|
| `replicas` | `1` | Stateful singleton — two pods sharing a volume and a `paperclip.agent_id` would both claim the same work. |
| `strategy.type` | `Recreate` | With `RollingUpdate` the new pod contends with the old one for the same volume. |
| `serviceAccountName` | one per agent | Bound to an IAM role via IRSA or EKS Pod Identity — this is the agent's runtime identity. Scope it per persona. |
| `securityContext` | `runAsUser/runAsGroup/fsGroup: 1000` | The images run as uid 1000 and must own their volume to write `instance.yaml`. |

## Persistent storage

A `PersistentVolumeClaim` mounted at `/data`. Use the **EFS CSI driver** rather than EBS unless you
have a reason not to: EBS `ReadWriteOnce` pins the pod to a single availability zone, which makes
rescheduling fragile. Any storage class your cluster provides will work.

`fsGroup: 1000` in the pod's `securityContext` is what makes the mounted volume group-writable by the
container's user. Without it the `instance.yaml` bootstrap fails on a permission error.

## Credentials

Project Secrets Manager values into the pod with the **AWS Secrets Store CSI Driver** (or the External
Secrets Operator if that is what you already run), mapped to the variable names used by the `*_ref`
fields in `instance.yaml`. See [credentials-and-secrets.md](credentials-and-secrets.md).

Two details that catch people out with the CSI driver:

- The CSI volume **must be mounted** in the container even if you consume the values via `envFrom`.
  Mounting is what triggers the driver to fetch the secrets and materialize the Kubernetes Secret.
- `secretObjects` in the `SecretProviderClass` is what creates that Kubernetes Secret. Without it the
  values exist only as files under the mount path, and `envFrom.secretRef` has nothing to read.

The template does both. For **Bedrock** as the model host, attach `bedrock:InvokeModel` to the
IRSA/Pod Identity role and leave `model_host.credentials_ref` unset instead of storing static keys.

## Image

`ghcr.io/stainedhead/agentic-team-w-paperclip/harness:latest` or `.../paperclip:latest`, published for
`linux/amd64` and `linux/arm64` — so Graviton node groups work without changes. Pin by digest for
anything you need to reproduce.

A private GHCR package needs an `imagePullSecret` in the target namespace.

## Getting the first configuration onto the volume

A fresh PVC is empty, so a pod starting against one would write the default `instance.yaml` and run
with it — which does nothing useful until filled in.

**The template handles this**: it ships a `ConfigMap` holding the instance's `instance.yaml` and an
init container that copies it onto the volume if the file is absent. The copy is guarded by
`[ -f /data/instance.yaml ] ||`, so it is a no-op on every later start and never overwrites a
configuration you have since changed on the volume. This keeps each agent's configuration in your
manifests, under version control, and makes the pod reproducible from nothing.

The alternative is to delete the ConfigMap and init container, let the container bootstrap its own
default, then `kubectl exec` in to edit it and restart. That is fine for experimentation, but it
leaves no record of what the instance is configured to do — prefer the ConfigMap for anything you
intend to keep.

## Namespacing the fleet

Nothing here assumes a particular namespace. Deploying the whole fleet into one namespace per
environment is the common choice; per-agent namespaces buy little, since the isolation that matters is
the IAM role and the volume, not the namespace.

## Observability

Pod stdout goes wherever your cluster's log pipeline sends it. The startup bootstrap logs the
personas, model host and agent id it resolved, and warns about any unresolvable `*_ref` — those lines
are how you confirm a pod is configured as intended.

## The harness+Paperclip variant

Two processes plus an embedded PostgreSQL: raise the resource requests/limits above the template's
starting point, add Paperclip's two boot secrets (`BETTER_AUTH_SECRET`,
`PAPERCLIP_TOOL_ACTION_SIGNING_SECRET`) to the `SecretProviderClass`, and uncomment the `Service` at
the end of the template to reach its UI/API in-cluster. If either process exits, the container exits
and the kubelet restarts it per the pod's `restartPolicy` — the intended behavior (ADR-0013).

## Updating

Update the Deployment's image reference to the new tag or digest. The existing PVC and its
`/data/instance.yaml` are reused unchanged — an image update never resets an instance's configuration.
