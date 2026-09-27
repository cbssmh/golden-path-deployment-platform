# Golden Path handoff state

## Purpose and snapshot boundary

This document is the continuation record for the Golden Path project as of
2026-09-27. It records completed scope, immutable release identities, verified
evidence, known limitations, and the next approved planning boundary.

This is a handoff document, not a claim that static controls have already been
enforced by a cluster. GitOps GP-3 is released as `v0.3.0`; the Platform GP-3
release candidate is at its pull-request review gate. Platform `v0.3.0` has
not been created, and GP-3 is not runtime-verified.

No live cluster is part of this handoff. The GP-2A runtime verification used a
disposable kind cluster. That cluster was removed after evidence collection.

## Current release identity

### Platform

- Repository: `golden-path-deployment-platform`
- Release: `v0.2.0`
- Commit: `6c4cbaf585d89f223c9a09836c5f2ebd0363194f`
- Annotated tag object: `24e0cd22ed730d4bb2fd61203e9273534ed613e2`

### GitOps

- Repository: `golden-path-gitops`
- Release: `v0.2.0`
- Commit: `cbd5ad7de7d73b93859e019f5d2a34705917c477`
- Annotated tag object: `193389d6d2271c1c8d7acf9e34f6d10e689c5da3`

### GP-3 release preparation

- GitOps release: `v0.3.0`
- GitOps commit: `7ca762c380cecc47af922344abe268c84bb398e4`
- GitOps annotated tag object:
  `232b0a8b8959c8447f5d0e809f40d350148fe198`
- Platform release candidate: `v0.3.0`
- Platform commit: intentionally not recorded until the governed merge

The Platform candidate records finalized upstream inputs without embedding a
self-referential Platform commit.

### Runtime inputs

- Service image:
  `ghcr.io/cbssmh/golden-path-service-a@sha256:5972389a2b99f26c89544528e4785655aaa422b54e7f0602b4a7b77a5c640916`
- Argo CD: `v3.4.5`
- Argo CD installation manifest SHA-256:
  `cdf6758b489d25641c2a1fd835642543aaa64fe530867d0136a83ddf3dafe456`
- Kubernetes: `v1.36.1`
- kind node image digest:
  `sha256:3489c7674813ba5d8b1a9977baea8a6e553784dab7b84759d1014dbd78f7ebd5`

The release tags and digests above are immutable release inputs. Do not move or
rewrite an existing release tag.

## Completed phases

### GP-1: Platform audit

GP-1 is complete. The audit established that:

- the default Argo CD AppProject was being used;
- the Argo CD application-controller retained cluster-wide authority;
- GitOps repository ownership boundaries were not enforced; and
- workload paths could request broader Kubernetes resources than intended.

### GP-2A: Argo CD trust boundary

GP-2A is complete and released as Platform and GitOps `v0.2.0`.

GP-2A answers:

> Who can deploy what?

It establishes a platform/workload ownership boundary with Argo CD
AppProjects. It does not establish workload pod-security requirements.

## Evidence classification

Use these labels without upgrading a claim beyond its evidence:

- `SOURCE-CONFIRMED`: the behavior or configuration is present in repository
  source and release definitions.
- `TEST-VERIFIED`: deterministic static tests exercised the repository
  contract.
- `RUNTIME-VERIFIED`: behavior was observed in the approved disposable
  runtime.
- `NOT RUNTIME-VERIFIED`: the behavior has not been directly observed in the
  approved runtime.

Current classification:

- AppProject and manifest definitions: `SOURCE-CONFIRMED`.
- GP-2A trust-boundary tests: `TEST-VERIFIED`.
- AppProject allowed and denied behavior: `RUNTIME-VERIFIED`.
- GP-3 manifests: `SOURCE-CONFIRMED`.
- GP-3 workload-security contract: `TEST-VERIFIED / STATIC`.
- GP-3 admission and runtime behavior: `NOT RUNTIME-VERIFIED`.

The Platform `v0.2.0` release manifest predates the separately approved GP-2A
runtime exercise and therefore records Argo enforcement as not runtime
verified. Treat that file as immutable historical release evidence. This
handoff records the later runtime result; do not rewrite the released manifest
to change its original evidence state.

## Current GP-2A architecture

### Platform-owned resources

The `golden-path-platform` AppProject manages:

- the workload AppProject;
- `Namespace/dev`; and
- the `service-a` Application.

The platform path owns changes to the trust boundary and namespace lifecycle.

### Workload-owned resources

The `golden-path-service-a` AppProject is restricted to:

- the approved GitOps repository;
- the in-cluster `dev` namespace; and
- `Deployment`, `Service`, and `ConfigMap` resources.

It does not permit:

- `Secret`;
- `ServiceAccount`;
- `Role`;
- `RoleBinding`;
- `ClusterRole`;
- `ClusterRoleBinding`;
- `Namespace`;
- `CustomResourceDefinition`;
- `StorageClass`; or
- arbitrary cluster-scoped resources.

Do not add `ServiceAccount` to the workload AppProject during GP-3. A Service
Account must remain platform-owned so the GP-2A workload boundary is
preserved.

### Default AppProject

The Argo CD `default` AppProject still exists, but it is locked down. It has no
source or destination deployment authority. Describe it as locked down, not as
deleted.

## GP-2A runtime verification

The approved runtime exercise used a fresh disposable kind cluster with
Kubernetes `v1.36.1` and Argo CD `v3.4.5`.

### Allowed path

The following state was observed for `service-a`:

- the Application was `Synced`;
- the Application was `Healthy`;
- the Deployment was available;
- the Pod was running and ready;
- the EndpointSlice had a ready endpoint; and
- the service endpoint returned the expected response.

Argo CD managed these workload resources:

- `ConfigMap/service-a`;
- `Service/service-a`; and
- `Deployment/service-a`.

The running image identity matched the approved Service A OCI digest.

### Denied path

Temporary Applications were used without automated sync. Argo CD rejected the
following through AppProject source, destination, or resource restrictions:

- an alternate repository;
- a `kube-system` destination;
- an `argocd` destination;
- `ClusterRoleBinding`;
- `Namespace`;
- `Secret`; and
- `ServiceAccount`.

The forbidden resources were not created. These results are
`RUNTIME-VERIFIED` AppProject enforcement, not merely static predictions.

### Reconciliation scope

The runtime exercise verified Git desired-state synchronization and
Application status. `selfHeal` remained disabled. Do not claim automatic drift
remediation from GP-2A.

## GP-2A limitations and residual risks

GP-2A does not prove:

- multi-tenancy;
- least-privileged Argo controller RBAC;
- that cluster compromise is impossible; or
- prevention of direct actions by a cluster administrator.

Known residual risks are:

- the Argo CD application-controller remains a high-trust component;
- a GitHub administrator can alter repository governance;
- compromise of platform-owned paths can alter Applications and AppProjects;
- future AppProject misconfiguration can broaden authority;
- GP-3 Pod security admission has not been runtime-verified;
- no NetworkPolicy is present;
- no ResourceQuota or LimitRange is present; and
- no Golden Path-specific admission policy is present.

## Current implementation phase: GP-3 Workload Security Baseline

GP-3 answers:

> What minimum security posture must an allowed workload satisfy?

The read-only audit and repository implementation are complete. GitOps
`v0.3.0` has completed governance and release. The Platform candidate has
entered governance; its merge, tag creation, and runtime phase remain pending.

### Current Service A posture

Source-confirmed controls in the implementation working tree:

- `runAsNonRoot: true`;
- `runAsUser: 10001`;
- `seccompProfile.type: RuntimeDefault`;
- `allowPrivilegeEscalation: false`;
- all Linux capabilities are dropped;
- `readOnlyRootFilesystem: true`;
- `serviceAccountName: service-a`;
- `automountServiceAccountToken: false`;
- CPU and memory requests and limits;
- readiness and liveness probes;
- an OCI digest image reference; and
- a Docker image user created with UID `10001`.

The Dockerfile's UID `10001` is image intent. It is not Kubernetes admission or
runtime enforcement. The Kubernetes manifest now requires UID `10001`, but the
effective process UID, seccomp profile, token-mount state, and PSA behavior have
not been runtime-verified.

## Implemented GP-3 design

This section records repository state. All claims remain source/static until
the separately approved runtime phase.

### Deployment security context

The Deployment declares these Pod-level controls:

- `runAsNonRoot: true`;
- `runAsUser: 10001`; and
- `seccompProfile.type: RuntimeDefault`.

It retains these container-level controls:

- `allowPrivilegeEscalation: false`;
- `capabilities.drop: [ALL]`; and
- `readOnlyRootFilesystem: true`.

Do not add a startup probe, explicit group policy, writable volume, or Linux
capability unless a demonstrated application requirement justifies it.

### Platform-owned ServiceAccount

`ServiceAccount/service-a` is defined as a platform-owned resource with:

- `automountServiceAccountToken: false` on the ServiceAccount; and
- `serviceAccountName: service-a` plus
  `automountServiceAccountToken: false` on the Pod.

Do not create a `Role`, `RoleBinding`, `ClusterRole`, or
`ClusterRoleBinding`. Service A has no identified requirement for Kubernetes
API access.

The new `service-a-identity` child Application uses the
`golden-path-service-a-identity` AppProject. That project accepts only the exact
GitOps repository, the `dev` destination, and the ServiceAccount kind. The
existing workload AppProject whitelist remains unchanged.

### Pod Security Admission

The platform-owned Namespace enables the Restricted Pod Security Standard on
`Namespace/dev` for Kubernetes `v1.36`:

```yaml
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/enforce-version: v1.36
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/audit-version: v1.36
pod-security.kubernetes.io/warn: restricted
pod-security.kubernetes.io/warn-version: v1.36
```

The hardened Deployment supplies the `runAsNonRoot` and seccomp fields required
for Restricted compatibility. Runtime admission remains unverified.

### Workload-security CI contract

The positive test validates the rendered hardened Service A Deployment,
Namespace, and ServiceAccount.

Nine negative fixtures verify detection of:

- `privileged: true`;
- UID `0`;
- `hostNetwork: true`;
- a `hostPath` volume;
- missing seccomp;
- missing ServiceAccount;
- automatic ServiceAccount token mounting;
- missing resource requirements; and
- a mutable image reference.

Keep evidence precise: PSA can enforce Pod Security Standard fields, but it
does not enforce probes, resources, digest-only images, the selected Service
Account, token automount policy, or read-only root filesystems. Those controls
remain CI-enforced until a later admission policy exists.

## Future roadmap

### GP-3: Workload security baseline

- GitOps `v0.3.0` is released with the exact identity recorded above.
- Platform `v0.3.0` is a release candidate awaiting governed merge and tag.
- Runtime verification remains pending.

### GP-4: Resource governance

- Add `ResourceQuota`.
- Add `LimitRange`.

### GP-5: CI security contract expansion

Expand the admission-like static contract and negative fixtures without
claiming cluster enforcement.

### GP-6: ValidatingAdmissionPolicy

Use Kubernetes built-in ValidatingAdmissionPolicy for Golden Path-specific
requirements that PSA cannot express.

Do not introduce Kyverno or Gatekeeper unless a concrete requirement appears
that the built-in controls cannot satisfy.

### GP-7: GitOps recovery evidence

Capture bounded recovery evidence for:

- drift;
- deletion;
- an invalid commit;
- rollback;
- controller restart; and
- full rebuild.

## Exact continuation instructions

The next session must:

1. Read this document before proposing or changing GP-3 files.
2. Verify that the Platform `v0.2.0` and GitOps `v0.2.0`/`v0.3.0` tags still
   resolve to the commits recorded above.
3. Review the Platform GP-3 pull request and preserve the finalized GitOps
   `v0.3.0` repository and tag unchanged.
4. Treat GP-3 manifests as `SOURCE-CONFIRMED`, contract tests as
   `TEST-VERIFIED / STATIC`, and all GP-3 runtime behavior as
   `NOT RUNTIME-VERIFIED`.
5. Confirm that `golden-path-service-a` remains unchanged and cannot create a
   ServiceAccount.
6. Confirm that `golden-path-service-a-identity` permits only ServiceAccount in
   `dev` and that no RBAC binding exists.
7. Obtain explicit approval before merging the Platform pull request or
   creating the Platform `v0.3.0` tag.
8. Keep governance/release and disposable runtime verification as
   separate approval gates.
9. Use only a fresh disposable kind cluster for future runtime verification.
10. Record source, test, and runtime evidence separately; never promote a
    static result to `RUNTIME-VERIFIED`.
11. Do not start GP-4, GP-5, GP-6, or GP-7 while completing GP-3.

Do not move release tags, modify GitHub governance, change Argo controller
RBAC, install policy engines, add NetworkPolicy, add resource governance, or
create a production dependency as part of GP-3.

## Handoff hygiene

This document intentionally contains no credentials, access tokens, Secrets,
private keys, temporary kubeconfigs, or cluster-admin configuration. Repository
and release identifiers are public integrity metadata, not credentials.
