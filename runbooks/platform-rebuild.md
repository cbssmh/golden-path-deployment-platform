# Platform rebuild runbook

Use the committed v0.1.1 release configuration or a local file that preserves
its pinned kind image, Argo CD manifest checksum, GitOps `v0.1.1` tag, and
Service A OCI digest. With the public GitOps repository reachable, run:

```bash
./bootstrap/destroy.sh
./bootstrap/kind/create-cluster.sh
./bootstrap/argocd/install.sh
./bootstrap/argocd/apply-root-application.sh
./scripts/verify-platform.sh
../golden-path-gitops/scripts/validate.sh
```

The Root Application is the only application resource applied by Platform; it
creates the Service A Application through Argo CD. Do not directly apply
Service A resources. Record command output in `evidence/releases/v0.1.1/`
without secrets, tokens, or Argo CD administrator passwords. For v0.1.1,
record the kind node image, Argo CD checksum result, both Application
`targetRevision` values, EndpointSlice readiness, Service A imageID, and HTTP
response in `evidence/releases/v0.1.1/`.
