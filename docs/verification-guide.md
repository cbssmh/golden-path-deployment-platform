# Verification guide

`make verify` checks the kind context and Ready node, Argo CD availability, both Argo CD applications being Synced and Healthy, the Service A rollout and ready Pod, then calls `make service-a-check`.

`make service-a-check` port-forwards the ClusterIP Service and requires the response fields `service-a`, `0.1.0`, and `running`.

## Current verification state

IMPLEMENTED BUT NOT RUNTIME VERIFIED. The public GitOps repository at `https://github.com/cbssmh/golden-path-gitops.git` must be created and populated on `main` before these runtime commands can succeed.
