# Environment check — 2026-07-15

| Tool | Result |
| --- | --- |
| Docker | `29.6.1`; daemon reachable outside the filesystem sandbox |
| kind | `v0.32.0` installed |
| kubectl | Client `v1.36.1`; bundled Kustomize `v5.8.1` |
| make | GNU Make `3.81` |
| git | `2.50.1` |
| ShellCheck | Not installed |
| yamllint | Not installed |
| kubeconform | Not installed |

Kubernetes bootstrap, Argo CD synchronization, and rebuild verification have
not been run because the public GitOps repository has not yet been created and
populated.
