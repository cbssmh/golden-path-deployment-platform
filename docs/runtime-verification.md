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
