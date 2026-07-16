# Platform rebuild runbook

With `config/platform.env.local` configured for a reachable public GitOps
repository, run:

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
Service A resources. Record command output in `evidence/releases/v0.1.0/`
without secrets, tokens, or Argo CD administrator passwords.
