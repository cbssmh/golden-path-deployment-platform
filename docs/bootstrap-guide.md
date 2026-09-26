# Bootstrap guide

1. Ensure the required tools and Docker daemon are available.
2. In the GitOps repository, run `./scripts/configure.sh`.
3. Use the protected GitOps `v0.2.0` release tag. Create the Platform
   `v0.2.0` tag only after its governed merge. Do not move `v0.1.1`.
4. Copy `config/platform.env.example` to `config/platform.env.local`.
5. Run `make prerequisites`, then `make bootstrap`.

Bootstrap applies the replacement platform project before restricting the
default project, then applies the Root Application. Expected result after the
separate runtime-approval gate: the `golden-path` kind context is active, Argo
CD is available, and Root Application and Service A are Synced and Healthy. If
bootstrap fails, inspect `kubectl get pods -A`, the Root Application, and
ensure the GitOps URL is public and reachable.
