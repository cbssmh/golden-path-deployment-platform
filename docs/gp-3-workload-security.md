# GP-3 workload security baseline

## Evidence state

GP-3 is at the Platform release-candidate review gate. GitOps `v0.3.0` is
finalized at commit `7ca762c380cecc47af922344abe268c84bb398e4`, with
annotated tag object `232b0a8b8959c8447f5d0e809f40d350148fe198`.
The Platform candidate is intended for `v0.3.0` and deliberately does not
embed its own future merge commit. Repository manifests and the
workload-security contract are `SOURCE-CONFIRMED` and `TEST-VERIFIED / STATIC`.
No GP-3 manifest has been applied to Kubernetes, so Pod Security Admission,
effective process identity, seccomp, and ServiceAccount token behavior remain
`NOT RUNTIME-VERIFIED`.

GP-2A and GP-3 establish different boundaries:

- GP-2A constrains which repository, destination, and Kubernetes resource
  kinds Argo CD Applications can deploy.
- GP-3 defines the minimum Pod security posture for an allowed workload.

The historical GP-2A release evidence remains unchanged.

## Workload contract

The Service A Pod declares:

- `runAsNonRoot: true`;
- `runAsUser: 10001`;
- `seccompProfile.type: RuntimeDefault`;
- `serviceAccountName: service-a`; and
- `automountServiceAccountToken: false`.

Its container declares:

- `allowPrivilegeEscalation: false`;
- `capabilities.drop: [ALL]`; and
- `readOnlyRootFilesystem: true`.

The existing OCI digest, CPU and memory requests and limits, readiness probe,
and liveness probe remain required. The contract does not add an `fsGroup`, a
writable volume, or an additional Linux capability.

## Platform-owned workload identity

`ServiceAccount/service-a` is owned by the platform identity path and disables
automatic token mounting. The workload Pod repeats the token automount opt-out
so its requirement remains explicit.

The `golden-path-service-a` AppProject remains unchanged and continues to allow
only Deployment, Service, and ConfigMap in `dev`. It cannot create a
ServiceAccount.

The `golden-path-service-a-identity` AppProject is restricted to:

- the exact Golden Path GitOps repository;
- the in-cluster `dev` namespace;
- no cluster-scoped resources; and
- the namespaced `ServiceAccount` kind only.

The platform-owned `service-a-identity` Application uses that project and
renders exactly one resource: `ServiceAccount/service-a`. No Role, RoleBinding,
ClusterRole, or ClusterRoleBinding is created.

## Pod Security Admission boundary

The platform-owned `Namespace/dev` selects the Restricted Pod Security
Standard in enforce, audit, and warn modes. Each mode is pinned to Kubernetes
`v1.36` so a Kubernetes upgrade requires an explicit policy-version review.

The labels apply only to `Namespace/dev`; GP-3 does not configure a global Pod
Security Admission default.

## Static contract evidence

The positive test validates the rendered Service A Deployment, Namespace, and
ServiceAccount. Negative mutation fixtures independently prove detection of:

- a privileged container;
- UID `0`;
- missing seccomp;
- host networking;
- a host path volume;
- a missing ServiceAccount;
- enabled token automount;
- missing resource requirements; and
- a mutable image tag.

These results are `TEST-VERIFIED / STATIC`. They do not demonstrate API-server
admission or runtime behavior.

## Deferred controls and residual risks

GP-3 does not add ValidatingAdmissionPolicy, Kyverno, Gatekeeper,
ResourceQuota, LimitRange, NetworkPolicy, image signatures, or attestations.
The Argo CD application-controller remains a high-trust cluster component.

PSA covers the standardized Pod Security profile, but it does not enforce the
Golden Path requirements for probes, resources, digest-only images, the exact
ServiceAccount, token automount, or a read-only root filesystem. Those controls
are static CI requirements until a later built-in admission-policy phase.
