# Problem statement

The target organization is a small SaaS team that needs a reproducible local
deployment foundation. The problem is that cluster setup and application
deployment can otherwise depend on undocumented manual state. v0.1.0 addresses
only a documented kind-to-Argo-CD-to-GitOps path for one example service.

## Golden Path definition

The Golden Path is the single deployment procedure officially supported by the
Platform Team. It gives developers the safest and most consistent default path
for deploying Service A, rather than requiring direct management of Kubernetes
application resources.
