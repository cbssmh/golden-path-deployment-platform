# GP-5 CI contract enforcement

## Objective

GP-5 makes repository validation fail before an invalid Golden Path change can
reach Argo CD or Kubernetes. It uses existing shell and Ruby validation rather
than adding a policy engine or a new test framework.

## Contract entrypoints

GitOps uses `scripts/validate.sh` as its single CI entrypoint. The script runs
render and template-drift validation, the separate GP-2A trust-boundary, GP-3
workload-security, and GP-4 resource-governance contracts, artifact checks,
kubeconform schema validation, and whitespace validation. The required GitHub
check remains `validate`.

Platform uses `make ci`. It runs linting, the existing trust-boundary and
release-identity tests through `make validate`, and
`scripts/verify-gitops-release.sh`. The remote verifier requires the recorded
GitOps tag to be annotated and compares both its tag object and peeled commit
with the release manifest. The required GitHub check remains
`static-validation`.

## Release identity evidence

The Platform v0.5.0 release candidate records the finalized GitOps v0.5.0
annotated tag object and peeled commit in
`releases/v0.5.0-release-manifest.yaml`. The release-identity test verifies the
structured metadata and `scripts/verify-gitops-release.sh` resolves the public
remote tag during CI. A mismatch, missing tag, lightweight tag, or unexpected
peeled target fails the Platform CI contract.

The Platform root Application targets GitOps v0.5.0 to consume the GP-5
repository contract. The workload, identity, and resource-governance child
Applications remain pinned to v0.4.0 because GP-5 changes CI behavior only and
does not change their runtime manifests.

## Evidence classification

- `SOURCE-CONFIRMED`: workflow definitions, entrypoints, semantic contract
  code, and fixtures are present in source.
- `TEST-VERIFIED`: positive manifests and isolated negative mutations execute
  through the repository CI contracts.
- `RUNTIME-VERIFIED`: existing GP-2A, GP-3, and GP-4 behavior was observed in
  separately approved disposable clusters.

CI does not prove Kubernetes admission or Argo reconciliation behavior. It
prevents known-invalid repository changes from reaching those runtime systems.

## Residual risks

Repository administrators can change workflows, tests, and rulesets. The
current single-maintainer model provides no independent reviewer. Static tests
can diverge from future Kubernetes behavior, third-party CI dependencies are
not yet pinned to immutable commits, and Service A repository governance is a
separate approval decision.
