# Verification guide

`make verify` checks the kind context and Ready node, Argo CD availability,
both Argo CD applications being Synced and Healthy, the Service A rollout and
ready Pod, then calls `make service-a-check`.

`make service-a-check` port-forwards the ClusterIP Service and requires the
response fields `service-a`, `0.1.0`, and `running`.

## Current verification state

RUNTIME VERIFIED on 2026-07-16. The complete kind, Argo CD, Root Application,
Service A, and destroy/rebuild lifecycle is recorded in
`docs/runtime-verification.md` and `evidence/releases/v0.1.0/`.
