# Environment check — 2026-07-16

| Tool | Result |
| --- | --- |
| Docker | `29.6.1`; daemon reachable |
| kind | `v0.32.0` |
| kubectl | Client `v1.36.1`; bundled Kustomize `v5.8.1` |
| make | GNU Make `3.81` |
| git | `2.50.1` |
| ShellCheck | Not installed locally; CI passed |
| yamllint | Not installed locally; CI passed |
| kubeconform | Not installed locally; GitOps CI passed |

`make prerequisites` passed. The required Docker daemon, kind, kubectl,
Kustomize, make, git, and curl were available.
