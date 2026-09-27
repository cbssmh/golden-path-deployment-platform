# Golden Path handoff

This document replaces the obsolete GP-3 implementation handoff. It is a
navigation record, not an additional source of security evidence.

## Current state

- Platform `v0.6.0` is the latest Platform release. It records GitOps
  `v0.6.0` as its historical release input.
- GitOps `v0.6.1` is the corrected GP-6 patch release. It contains CEL that
  type-checks cleanly on Kubernetes `v1.36.1` and points the admission
  Application to `v0.6.1`.
- GP-2A, GP-3, and GP-4 are runtime-verified.
- GP-5 and SC-1 are released and test-verified.
- GP-6 Warn/Audit behavior is runtime-verified. Deny/Audit was observed only
  through a temporary disposable runtime change and is not released.
- The released GP-6 binding remains `Warn/Audit`.

## Authoritative continuation references

Read these documents before proposing another phase:

1. [Architecture and ownership](architecture.md)
2. [Security evidence and release identity](security-evidence.md)
3. [Security threat model and residual risks](security-threat-model.md)
4. [Repository responsibilities](repository-responsibilities.md)
5. [Scope and non-goals](scope-and-non-goals.md)

Historical release manifests remain immutable evidence of what each Platform
release recorded at creation time. Do not rewrite an older manifest to reflect
later runtime evidence or the GitOps `v0.6.1` patch.

## Required claim discipline

- Do not describe the platform as multi-tenant or the Argo controller as
  least-privileged.
- Do not describe GP-6 Deny as released enforcement.
- Do not claim a Platform `v0.6.1` release.
- Do not claim signing, SBOM enforcement, trusted provenance verification,
  vulnerability policy, or NetworkPolicy.
- Treat disposable kind evidence as bounded local runtime evidence, not
  production qualification.
