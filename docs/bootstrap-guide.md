# Bootstrap guide

1. Ensure the required tools and Docker daemon are available.
2. In the GitOps repository, run `./scripts/configure.sh`.
3. Use the GitOps tag recorded by the selected protected Platform release.
   Platform `v0.6.0` records GitOps `v0.6.0`; the corrected admission policy
   is released separately as GitOps `v0.6.1` and requires a future governed
   Platform release before it becomes the Platform default.
4. Copy `config/platform.env.example` to `config/platform.env.local`.
5. Run `make prerequisites`, then `make bootstrap`.

Bootstrap applies the replacement platform project before restricting the
default project, then applies the Root Application. The expected result is an
active `golden-path` kind context, available Argo CD, and Synced/Healthy Root
and Service A Applications. Runtime evidence remains bounded to approved
disposable exercises. If bootstrap fails, inspect `kubectl get pods -A`, the
Root Application, and ensure the GitOps URL is public and reachable.
