# Golden Path security threat model

## Status and scope

This threat model describes the verified Golden Path architecture through
GitOps `v0.6.1`. Platform `v0.6.0` remains the latest Platform release. The
model covers repository governance, CI, image production, release identity,
Argo CD, Kubernetes admission, and Service A in Namespace `dev`.

The runtime evidence comes from disposable kind clusters running Kubernetes
`v1.36.1`. It is not evidence of production, multi-cluster, high-availability,
or multi-tenant operation.

## Assets

- the Platform, GitOps, and Example Services GitHub repositories;
- protected `main` branches and protected `v*` release tags;
- required CI workflows, pinned Actions, and pinned CI tools;
- GitOps desired state and annotated release identities;
- the Service A build workflow, GHCR repository, and OCI image digests;
- the Argo CD application-controller, Applications, and AppProjects;
- Namespace `dev` and its Pod Security Admission labels;
- `ServiceAccount/service-a` and the absence of workload RBAC bindings;
- `ResourceQuota/dev-resource-budget` and
  `LimitRange/dev-container-boundary`;
- `ValidatingAdmissionPolicy/golden-path-deployment-contract` and its binding;
- the Service A Deployment, Service, ConfigMap, Pod, and endpoint.

## Trust boundaries

1. A contributor crosses the repository boundary by opening a pull request.
2. A pull request crosses the merge boundary only after its required CI check.
3. The Service repository crosses the publisher boundary only in the
   post-test `publish` job, which alone has `packages: write`.
4. GHCR content crosses into GitOps only through an explicitly reviewed OCI
   digest; publication does not update GitOps automatically.
5. A protected GitOps tag crosses into Argo CD as immutable desired state.
6. Each Argo Application crosses an AppProject repository, destination, and
   resource-kind boundary.
7. A Deployment request in an opted-in namespace crosses the GP-6 VAP
   boundary. The released binding records warnings and audit actions; it does
   not deny.
8. A resulting Pod crosses the Restricted Pod Security Admission boundary.
9. The workload crosses the identity boundary through the platform-owned,
   tokenless `ServiceAccount/service-a`.
10. Namespace consumption crosses ResourceQuota aggregate budgets and
    LimitRange per-container maxima.

## Threat analysis

### Malicious GitOps manifest

- **Affected asset:** GitOps desired state and the cluster.
- **Attack or failure path:** a change requests an unapproved source,
  destination, or Kubernetes kind.
- **Existing control:** protected PR workflow, fail-closed semantic tests, and
  dedicated AppProjects.
- **Evidence:** GP-2A is `TEST-VERIFIED` and `RUNTIME-VERIFIED`; alternate
  repository, forbidden destination, and forbidden-kind fixtures were
  rejected and their resources were absent.
- **Residual risk:** a repository administrator or compromised platform-owned
  path can change both the desired resource and its boundary.
- **Future mitigation:** independent review if the maintainer model expands.

### AppProject broadening

- **Affected asset:** workload and platform ownership boundaries.
- **Attack or failure path:** a project whitelist adds repositories,
  namespaces, kinds, or cluster resources.
- **Existing control:** exact semantic assertions for every AppProject and
  required CI before merge.
- **Evidence:** GP-2A static tests and runtime allow/deny fixtures.
- **Residual risk:** the Argo controller remains highly trusted, and the same
  administrator can change policy and desired state.
- **Future mitigation:** independent policy review and controller RBAC
  reduction if a concrete operating model requires it.

### Cross-namespace deployment

- **Affected asset:** namespaces outside `dev`.
- **Attack or failure path:** an Application targets `kube-system`, `argocd`,
  or another namespace.
- **Existing control:** exact AppProject destinations.
- **Evidence:** `kube-system` and `argocd` destination fixtures were rejected
  at runtime.
- **Residual risk:** cluster administrators and the Argo controller identity
  can operate outside this boundary.
- **Future mitigation:** reduce controller scope only with a tested bootstrap
  and recovery design.

### Cluster-scoped resource creation

- **Affected asset:** cluster-wide authorization and API behavior.
- **Attack or failure path:** a workload requests Namespace, CRD, RBAC, or
  another cluster-scoped object.
- **Existing control:** the workload AppProject has no cluster-resource
  whitelist; platform projects are narrowly scoped.
- **Evidence:** Namespace and ClusterRoleBinding runtime fixtures, plus static
  CRD, StorageClass, and arbitrary cluster-resource fixtures.
- **Residual risk:** platform-owned admission resources are intentionally
  cluster-scoped, and cluster administrators remain outside AppProject
  enforcement.
- **Future mitigation:** retain separate platform ownership and review every
  cluster-scoped addition.

### Privileged, root, or host-level Pod

- **Affected asset:** node and container runtime.
- **Attack or failure path:** a Pod requests privilege, UID `0`, host access,
  or an unsafe security profile.
- **Existing control:** Restricted PSA on `dev`, hardened Service A security
  contexts, and GP-3 semantic tests.
- **Evidence:** effective UID `10001`, zero effective capabilities,
  `NoNewPrivs`, seccomp filter mode, and PSA rejection fixtures were observed
  at runtime.
- **Residual risk:** cluster administrators can alter namespace labels or use
  exempt namespaces; kernel and runtime vulnerabilities remain possible.
- **Future mitigation:** keep PSA versions explicit during Kubernetes
  upgrades and reassess runtime isolation if threat exposure changes.

### ServiceAccount token abuse

- **Affected asset:** Kubernetes workload identity.
- **Attack or failure path:** a projected API token is mounted and stolen.
- **Existing control:** a dedicated platform-owned ServiceAccount with
  `automountServiceAccountToken: false` on both ServiceAccount and Pod, with no
  RoleBinding or ClusterRoleBinding.
- **Evidence:** no `kube-api-access` projected volume or mounted token was
  present at runtime.
- **Residual risk:** future workload changes can request other credentials;
  cluster administrators can add RBAC or tokens.
- **Future mitigation:** add scoped workload identity only when an API-access
  requirement exists.

### Mutable or wrong-registry image substitution

- **Affected asset:** runtime artifact identity.
- **Attack or failure path:** a tag is retargeted or an image comes from an
  unapproved registry.
- **Existing control:** digest-pinned GitOps image, CI checks, and GP-6 image
  shape and `ghcr.io/cbssmh/` registry validations.
- **Evidence:** CI negative fixtures passed; Warn/Audit warnings and temporary
  Deny/Audit rejections were observed for mutable and wrong-registry images.
- **Residual risk:** a digest identifies bytes but does not prove authorship,
  provenance, vulnerability status, or safety.
- **Future mitigation:** signing, trusted provenance, and vulnerability policy
  only in separately approved phases.

### Missing probes or resource declarations

- **Affected asset:** workload availability and resource predictability.
- **Attack or failure path:** a Deployment omits readiness, liveness, or CPU
  and memory declarations.
- **Existing control:** GP-3/GP-5 semantic CI and GP-6 Deployment validations.
- **Evidence:** missing-probe and missing-resource fixtures passed static
  tests, warned in Warn/Audit, and were rejected in temporary Deny/Audit.
- **Residual risk:** field presence does not prove probe quality or resource
  sizing correctness.
- **Future mitigation:** tune values from measured service behavior rather
  than add another presence check.

### Excessive replicas

- **Affected asset:** namespace capacity and service availability.
- **Attack or failure path:** a Deployment requests more replicas than the
  bounded contract.
- **Existing control:** CI requires rolling-update budget fit; GP-6 permits
  one through four replicas; ResourceQuota limits actual Pod creation.
- **Evidence:** the GP-4 runtime showed that a Deployment object can be
  admitted while quota limits its Pods; GP-6 temporary Deny rejected a
  Deployment above four replicas.
- **Residual risk:** released GP-6 Warn/Audit does not reject the Deployment,
  and four replicas may still be inappropriate for a future workload.
- **Future mitigation:** move to Deny only through a governed release after
  operational acceptance.

### Namespace resource exhaustion

- **Affected asset:** availability of Namespace `dev`.
- **Attack or failure path:** aggregate CPU, memory, Pod, Service, or ConfigMap
  use consumes the namespace budget.
- **Existing control:** ResourceQuota aggregate hard limits and LimitRange
  per-container CPU and memory maxima.
- **Evidence:** Service A was admitted; excessive per-container and aggregate
  CPU, memory, and Pod fixtures were rejected at runtime.
- **Residual risk:** there is no ephemeral-storage quota, and quota values do
  not guarantee fair sharing or correct sizing.
- **Future mitigation:** add storage or object-count limits only after measured
  demand demonstrates a need.

### CI contract bypass

- **Affected asset:** protected repository state.
- **Attack or failure path:** invalid content reaches `main` without the
  semantic suite.
- **Existing control:** active pull-request rulesets, strict required checks,
  blocked force push and deletion, and no bypass actors.
- **Evidence:** GP-5 required checks and SC-1 Service governance were read back
  from GitHub; repository tests fail closed.
- **Residual risk:** repository administrators can alter governance and the
  single-maintainer model has no independent reviewer.
- **Future mitigation:** independent approval when team size supports it.

### Malicious or mutable GitHub Action

- **Affected asset:** CI credentials, source, and published images.
- **Attack or failure path:** an Action tag moves or an unapproved Action runs.
- **Existing control:** external Actions use full commit SHAs; static tests
  reject mutable references; Service Actions are allowlisted and repository
  SHA-pinning enforcement is active.
- **Evidence:** SC-1 source and remote policy readback are `RELEASED`.
- **Residual risk:** pinned upstream code may still be malicious, and GitHub
  hosted runners remain an external dependency.
- **Future mitigation:** periodic reviewed pin updates and runner isolation if
  the operating risk justifies it.

### Mutable CI tool download

- **Affected asset:** validation integrity.
- **Attack or failure path:** `latest` or an unchecked archive changes the
  validator being executed.
- **Existing control:** explicit versions, checksums, dependency hashes,
  package locks, and download-verify-extract sequencing.
- **Evidence:** SC-1 pin tests and successful required checks.
- **Residual risk:** package registries and download hosts remain external;
  checksums authenticate expected bytes, not publisher intent.
- **Future mitigation:** mirror tools only if external availability becomes an
  operational requirement.

### Mutable Docker base image

- **Affected asset:** Service A filesystem and runtime dependencies.
- **Attack or failure path:** a readable base tag resolves to different bytes.
- **Existing control:** the Dockerfile uses the reviewed manifest-list digest
  for Python 3.12.12 on Alpine 3.21.
- **Evidence:** SC-1 source test and successful multi-architecture build.
- **Residual risk:** the pinned base may contain vulnerabilities and receives
  no automatic update.
- **Future mitigation:** reviewed digest refresh and separately approved image
  scanning.

### Service-repository direct push

- **Affected asset:** Service A source and publisher workflow.
- **Attack or failure path:** a change bypasses `test-and-build` on `main`.
- **Existing control:** active `main-governance` requires a pull request and
  strict `test-and-build`; force push and deletion are blocked with no bypass.
- **Evidence:** SC-1 ruleset readback and governed PR #1 merge.
- **Residual risk:** zero approvals are required in the single-maintainer
  model.
- **Future mitigation:** require independent approval if another qualified
  maintainer is available.

### Release-tag movement

- **Affected asset:** release identity and reproducibility.
- **Attack or failure path:** a `v*` tag is updated or deleted after release.
- **Existing control:** active tag rulesets block update and deletion with no
  bypass actors; annotated tag objects and peeled commits are verified.
- **Evidence:** GP-2A through GP-6 release gates and remote identity checks.
- **Residual risk:** GitHub administrators can change rulesets.
- **Future mitigation:** external transparency or replication only if release
  assurance requirements grow.

### Argo controller compromise

- **Affected asset:** the Kubernetes cluster.
- **Attack or failure path:** the high-trust controller credential is abused.
- **Existing control:** AppProjects constrain accepted Applications; platform
  paths and repository merges are protected.
- **Evidence:** GP-2A runtime proves AppProject behavior, not controller least
  privilege.
- **Residual risk:** the application-controller retains cluster-wide, high
  trust and can become a cluster-impacting compromise path.
- **Future mitigation:** controller RBAC reduction or separate Argo instances
  only after a recovery-aware design.

### Cluster-admin bypass

- **Affected asset:** every Kubernetes-side control.
- **Attack or failure path:** an administrator alters labels, policies,
  bindings, quota, desired state, or workloads directly.
- **Existing control:** none that can constrain a legitimate cluster
  administrator; repository and runtime evidence provide detection context.
- **Evidence:** explicitly outside the bounded claims.
- **Residual risk:** complete bypass remains possible.
- **Future mitigation:** external access governance and audit retention in a
  production operating environment.

### Admission-policy misconfiguration or bad CEL

- **Affected asset:** Deployment availability and update safety.
- **Attack or failure path:** an expression fails type checking, misses an
  invalid object, or blocks a valid update under Deny.
- **Existing control:** separate readable validations, semantic fixtures,
  Kubernetes `v1.36.1` type checking, Warn/Audit rollout, and governed changes.
- **Evidence:** corrected CEL has `observedGeneration == generation`, empty
  `status.typeChecking`, and no `expressionWarnings`; valid Service A remained
  healthy during Warn/Audit and temporary Deny/Audit tests.
- **Residual risk:** the released binding is not Deny; a future Deny policy can
  still cause admission outages.
- **Future mitigation:** repeat disposable runtime tests before any governed
  Deny release and retain a documented recovery path without standing bypass.

## Explicitly absent controls

The current Golden Path has no NetworkPolicy, SBOM enforcement, image signing,
trusted provenance verification, vulnerability-scanning policy, production
audit-retention guarantee, or independent reviewer. These are residual risks,
not implied features.
