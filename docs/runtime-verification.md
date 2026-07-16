# Runtime verification

The kind Bootstrap lifecycle was runtime-verified on 2026-07-16.

- The first fresh creation is recorded in
  `evidence/releases/v0.1.0/bootstrap-result.txt`.
- The cluster was destroyed and its absence confirmed before the rebuild.
- The rebuild and its verification are recorded in
  `evidence/releases/v0.1.0/rebuild-result.txt`.

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get ns
```

The executed checks confirmed that `kubectl cluster-info` connected to the
cluster, the control-plane node was Ready, and the Kubernetes namespaces were
listed for both runs. The executed absence checks confirmed that the `argocd`
namespace was not present and that only standard kind system workloads were
present; no Service A or other application workload was deployed. The evidence
files contain the captured command output.

## Argo CD Bootstrap

Argo CD Bootstrap was runtime-verified on 2026-07-16. The installation and
readiness output is recorded in `evidence/releases/v0.1.0/argocd-status.txt`.

The verification confirmed that the `argocd` namespace exists, all Argo CD
pods are Ready, and all Argo CD Deployments are Available. No Argo CD
Application exists, and no Service A resource is present. Root Application
deployment and GitOps synchronization are not part of this milestone.

## Root Application

Root Application deployment was runtime-verified on 2026-07-16. The captured
application state is recorded in
`evidence/releases/v0.1.0/verification-result.txt`.

Argo CD accepted `root-applications` and reported it `Synced` and `Healthy`
with repository `https://github.com/cbssmh/golden-path-gitops.git`, revision
`main`, path `applications/root`, and destination namespace `argocd` on
`https://kubernetes.default.svc`.

The frozen Root Application source automatically created a `service-a` child
Application. The required cluster listing observed a Service A workload in the
`dev` namespace. Service A runtime verification was not performed at the Root
Application milestone.

## Service A Runtime Verification

Service A runtime verification was completed on 2026-07-16. The captured
Application, resource, endpoint, and validation output is recorded in
`evidence/releases/v0.1.0/verification-result.txt`; the exact HTTP response is
recorded in `evidence/releases/v0.1.0/endpoint-response.json`.

The `service-a` Application is `Synced` and `Healthy`, with source path
`services/service-a/overlays/dev`. The Deployment is Available, its Pod is
Ready, the ClusterIP Service has endpoint `10.244.0.12:8080`, and the
repository's temporary port-forward verifier returned the expected JSON
response. The existing GitOps validation script rendered the frozen Kustomize
paths successfully.

## Full Platform Destroy/Rebuild Verification

The complete v0.1.0 destroy/rebuild workflow was runtime-verified on
2026-07-16. The captured pre-destroy state, absence confirmation, interrupted
foreground installer output, and final successful rebuild output are recorded
in `evidence/releases/v0.1.0/rebuild-result.txt`.

The verified workflow is: `./bootstrap/destroy.sh`,
`./bootstrap/kind/create-cluster.sh`, `./bootstrap/argocd/install.sh`,
`./bootstrap/argocd/apply-root-application.sh`,
`./scripts/verify-platform.sh`, and
`../golden-path-gitops/scripts/validate.sh`.

The rebuilt cluster has a Ready control-plane, healthy Argo CD components,
`root-applications` and `service-a` both `Synced` and `Healthy`, an Available
Service A Deployment with a Ready Pod and active endpoint, and the expected
runtime JSON response. No Service A resource was manually applied.
