# Golden Path security evidence

## Evidence vocabulary

- **SOURCE-CONFIRMED:** the exact configuration or contract exists in source.
- **TEST-VERIFIED:** deterministic positive and negative tests exercised the
  source contract.
- **RUNTIME-VERIFIED:** the stated behavior was directly observed in an
  approved disposable runtime.
- **RELEASED:** the change passed repository governance and has an immutable
  release identity where the repository uses release tags.
- **TEMPORARY RUNTIME OBSERVATION:** behavior was observed after an explicit
  disposable runtime-only change that is not the released state.

These labels do not transfer automatically. Static CI evidence does not prove
Kubernetes behavior, and a temporary Deny observation does not make Deny the
released GP-6 state.

## Current release identity

<!-- markdownlint-disable MD013 -->

| Component | Identity | Exact object or commit | State |
| --- | --- | --- | --- |
| Platform | `v0.6.0` | tag object `35145a9d639c1fe4b968d200ca0841c0fa10ad83`; commit `20f6155086850e4ce271da888eae15d34509fcce` | `RELEASED` |
| GitOps | `v0.6.1` | tag object `8a64df53d3894af77e8ee9e0fe00c9a218f5120d`; commit `f8efd8b82ffdaf44dd990f542c68c1921f03844c` | `RELEASED` |
| GitOps predecessor | `v0.6.0` | tag object `16d23df55b81d423c30f754e33916b499b30ece6`; commit `fbca34e75c4974581a05e371c315cbdde0159f9b` | unchanged historical release |
| Deployed Service A | OCI digest | `sha256:5972389a2b99f26c89544528e4785655aaa422b54e7f0602b4a7b77a5c640916` | runtime-observed in GP-2A through GP-4 |
| Argo CD | `v3.4.5` | manifest SHA-256 `cdf6758b489d25641c2a1fd835642543aaa64fe530867d0136a83ddf3dafe456` | source and runtime verified |
| kind node | Kubernetes `v1.36.1` | image digest `sha256:3489c7674813ba5d8b1a9977baea8a6e553784dab7b84759d1014dbd78f7ebd5` | source and runtime verified |

<!-- markdownlint-enable MD013 -->

Platform `v0.6.0` records GitOps `v0.6.0`. The corrected GP-6 CEL and admission
Application self-reference are released separately as GitOps `v0.6.1`.
Documentation does not claim a Platform `v0.6.1` release or silently rewrite
the historical Platform manifest.

## Current enforcement matrix

<!-- markdownlint-disable MD013 -->

| Contract | Owner | Source | Tests | Runtime | Released enforcement state |
| --- | --- | --- | --- | --- | --- |
| Repository, destination, and allowed kinds | Argo CD AppProjects | confirmed | verified | verified | enforced by AppProjects |
| Default project deployment authority | Platform bootstrap | confirmed | verified | verified | locked down, not deleted |
| Non-root, seccomp, privilege, capabilities, and host access | Restricted PSA plus workload manifest | confirmed | verified | verified | PSA `enforce`, `audit`, and `warn` on `dev` |
| Dedicated tokenless identity | Identity AppProject, ServiceAccount, and Pod | confirmed | verified | verified | token automount disabled; no RBAC binding |
| Aggregate namespace budget | ResourceQuota | confirmed | verified | verified | enforced by Kubernetes |
| Per-container CPU and memory maximum | LimitRange | confirmed | verified | verified | enforced by Kubernetes |
| Digest, registry, ServiceAccount, token, root filesystem, probes, resources, and replica contract | ValidatingAdmissionPolicy | confirmed | verified | Warn/Audit and temporary Deny observed | released binding is `Warn/Audit`; Deny is not released |
| GitOps and Platform PR contract | required CI and rulesets | confirmed | verified | not a Kubernetes runtime claim | `validate` and `static-validation` required |
| Service PR and publish contract | required CI, rulesets, and workflow permissions | confirmed | verified | successful hosted workflow observed | `test-and-build` required; publish permission isolated |
| Build input immutability | SC-1 workflow, installer, and Dockerfile contracts | confirmed | verified | successful build/publish observed | Actions, tools, schemas, and base image pinned |
| Release identity | protected annotated tags and remote verifier | confirmed | verified | remote tag resolution observed | tag update/deletion blocked |

<!-- markdownlint-enable MD013 -->

## GP-2A: Argo CD trust boundary

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`,
`RUNTIME-VERIFIED`, `RELEASED`.

- `root-applications` used `golden-path-platform` and Service A used
  `golden-path-service-a`.
- The allowed Service A Application reached `Synced` and `Healthy`; its
  Deployment was available, its Pod was Ready, and its endpoint responded.
- Its managed workload resources were exactly Deployment, Service, and
  ConfigMap in `dev`.
- Alternate repository, `kube-system`, `argocd`, ClusterRoleBinding,
  Namespace, Secret, and ServiceAccount fixtures were rejected through the
  AppProject boundary.
- Absence checks confirmed that the forbidden resources were not created.
- The `default` AppProject remains present but has no deployment authority.

This proves the tested Argo allow/deny boundary. It does not prove Argo
controller least privilege, multi-tenancy, or resistance to cluster-admin
mutation.

## GP-3: workload security baseline

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`,
`RUNTIME-VERIFIED`, `RELEASED`.

- The running process used UID `10001`.
- Effective capabilities were zero (`CapEff` all zeroes).
- `NoNewPrivs` was active and seccomp was in filter mode.
- The container root filesystem was read-only.
- The effective Pod selected `ServiceAccount/service-a`; both ServiceAccount
  and Pod disabled automatic token mounting.
- No `kube-api-access` projected volume or mounted ServiceAccount token was
  present.
- No RoleBinding or ClusterRoleBinding granted workload API access.
- The compliant Pod became Ready and its endpoint responded.
- Restricted PSA rejected privileged, UID `0`, host-network, host-path, and
  missing-seccomp Pods; absence checks confirmed they were not created.

Docker `USER 10001` is image intent. The Pod security context and Restricted
PSA are the Kubernetes-side controls.

## GP-4: resource governance

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`,
`RUNTIME-VERIFIED`, `RELEASED`.

`ResourceQuota/dev-resource-budget` exposed these hard values:

| Resource | Hard value |
| --- | --- |
| `requests.cpu` | `250m` |
| `requests.memory` | `256Mi` |
| `limits.cpu` | `500m` |
| `limits.memory` | `512Mi` |
| `pods` | `6` |
| `services` | `5` |
| `configmaps` | `10` |

The API also reported live `used` counters for the running Service A
resources. Those counters changed with fixture creation and cleanup, so they
are runtime observations rather than immutable release fields.

`LimitRange/dev-container-boundary` enforced maximum CPU `250m` and memory
`256Mi` per container. Runtime evidence showed:

- Service A was admitted, Ready, and continued to serve its endpoint;
- a container exceeding a LimitRange maximum was rejected and absent;
- aggregate CPU, memory, and Pod-count exhaustion attempts were rejected by
  ResourceQuota and their Pods were absent; and
- an excessive-replica Deployment object could be admitted while quota
  prevented all requested Pods from being created.

The last result is intentional evidence: ResourceQuota constrains realized
resource consumption, not the Deployment replica field.

## GP-5: CI contract enforcement

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`, `RELEASED`.

- GitOps `scripts/validate.sh` is the fail-closed `validate` entrypoint.
- Platform `make ci` is the fail-closed `static-validation` entrypoint.
- GP-2A, GP-3, GP-4, and GP-6 semantic contracts remain separate and readable.
- Generated manifest drift is rejected by configure/check validation.
- Schema, YAML, shell, Markdown, whitespace, artifact, and credential checks
  execute through the repository validation paths as applicable.
- Platform remote verification requires an annotated GitOps tag object and
  its exact peeled commit, not only a matching string.

GP-5 is CI evidence. It does not by itself prove Argo reconciliation or
Kubernetes admission behavior.

## SC-1: supply-chain foundation

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`, `RELEASED`.

- External GitHub Actions are pinned to full commit SHAs, with readable release
  comments; static contracts reject mutable external Action references.
- kubectl `v1.36.1`, kubeconform `v0.8.0`, ShellCheck `v0.11.0`, runtime
  versions, dependency hashes, the Kubernetes schema commit, and the
  Markdown package lock are explicit where used.
- Installers download, verify checksums, then extract; checksum mismatch fails
  closed.
- The Service Dockerfile pins Python 3.12.12 on Alpine 3.21 to base
  manifest-list digest
  `sha256:d4f9227f21409479c7fe92288f2e40b1a56ae591c8ad3b5446dfeaef90f67857`.
- Service `test-and-build` has read-only contents permission and is required on
  pull requests. The dependent `publish` job is the only job with
  `packages: write` and is skipped on pull requests.
- Active Service `main-governance` requires a current pull request with the
  `test-and-build` check from GitHub Actions integration `15368`; force push
  and deletion are blocked with no bypass actors and zero approvals.
- Active Service `release-tag-protection` blocks `v*` update and deletion with
  no bypass actors while allowing creation.
- The Service Actions policy allows only the workflow's approved Action
  repositories and requires SHA pinning.

The successful main workflow run `36313661725` built and published source
commit `37a08f0e837635f15bea1bd692ac1a9997789912` as:

- tag `37a08f0e837635f15bea1bd692ac1a9997789912`;
- OCI index digest
  `sha256:2d1e6fc4a21976b3b5c5792399b43fec491c59ba9a1d7277773126f202b4abd5`;
- linux/amd64 digest
  `sha256:34b379404d6a3f68dd642e7ac4194a094c80131aad2851ec14b2ac64d5b10425`;
- linux/arm64 digest
  `sha256:f0bbbc771f9e3d90a8f34fad21223005d8cb79faa4465dcc45ac090ae2ae4ec7`.

That publication did not change the GitOps deployment digest. No signing,
trusted provenance verification, SBOM enforcement, or vulnerability policy is
claimed.

## GP-6: ValidatingAdmissionPolicy

**Classification:** `SOURCE-CONFIRMED`, `TEST-VERIFIED`, `RELEASED` at GitOps
`v0.6.1`; Warn/Audit is `RUNTIME-VERIFIED`; Deny/Audit is a
`TEMPORARY RUNTIME OBSERVATION` only.

- Kubernetes `v1.36.1` accepted the corrected policy with
  `observedGeneration == generation`, empty `status.typeChecking`, and no
  `expressionWarnings`.
- The released binding selects opted-in Namespace `dev` and declares
  `validationActions: [Warn, Audit]`.
- A compliant Service A Deployment produced no policy warning, remained
  admitted and healthy, and its endpoint responded.
- Warn/Audit produced the expected policy warning for nine invalid Deployment
  fixtures while leaving the API request non-denying, as designed.
- A temporary runtime-only switch to `Deny` and `Audit` rejected all nine
  fixtures: mutable image, wrong registry, default ServiceAccount, enabled
  token automount, writable root filesystem, missing readiness probe, missing
  liveness probe, missing resources, and replicas above four.
- Each Deny response named
  `golden-path-deployment-contract`, included its validation message, and an
  absence check confirmed that no invalid Deployment existed.
- The temporary binding change was restored and the disposable cluster was
  deleted. The released binding remains Warn/Audit.

The kind exercise observed API warnings; durable production audit-log capture
is not claimed.

## Residual risks

- The Argo application-controller remains cluster-wide and highly trusted.
- Cluster administrators can bypass or alter Kubernetes policies.
- Single-maintainer repositories have no independent reviewer.
- GP-6 Deny is not the released state.
- GP-6 is Deployment-only and namespace opt-in; direct Pods are outside its
  scope.
- Probe presence does not prove probe quality.
- Resource presence and limits do not prove sizing correctness.
- There is no NetworkPolicy, SBOM enforcement, image signing, trusted
  provenance verification, or vulnerability-scanning policy.
- GitHub-hosted runners and upstream distribution services remain external
  dependencies.
- Runtime evidence comes from disposable kind `v1.36.1`, not production,
  multi-cluster, or high-availability operation.
- Platform `v0.6.0` still records GitOps `v0.6.0`; consuming the corrected
  GitOps `v0.6.1` identity through a Platform release requires a separate
  governed Platform change.

See the [security threat model](security-threat-model.md) for threat-specific
attack paths, controls, and remaining exposure.
