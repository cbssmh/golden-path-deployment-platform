# Bootstrap guide

1. Ensure the required tools and Docker daemon are available.
2. In the GitOps repository, run `./scripts/configure.sh`.
3. Make that GitOps repository available as the configured public remote on
   `main`.
4. Copy `config/platform.env.example` to `config/platform.env.local`.
5. Run `make prerequisites`, then `make bootstrap`.

Expected result: the `golden-path` kind context is active, Argo CD is
available, and Root Application and Service A are Synced and Healthy. If
bootstrap fails, inspect `kubectl get pods -A`, the Root Application, and
ensure the GitOps URL is public and reachable.
