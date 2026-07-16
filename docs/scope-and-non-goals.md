# Scope and non-goals

Included: one kind cluster, Argo CD, an App-of-Apps Root Application, Service
A in `dev`, Kustomize, static validation, runtime checks, rebuild
documentation, and evidence structure.

Excluded: Service B, stage, self-service workflows, `workflow_dispatch`, image
automation, GitOps PR automation, Trivy, drift self-healing, rollback
automation, cloud infrastructure, remote state, monitoring, HPA,
NetworkPolicy, Vault, Backstage, service mesh, Crossplane, operators,
multiple clusters or clouds, databases, authentication, REST APIs, AI
features, and production-readiness claims.

## Why these are non-goals

- **Service B:** One workload is sufficient to prove the v0.1.0 deployment
  path.
- **stage:** A single `dev` environment isolates the reproducibility question.
- **Self-service workflows:** The goal is a documented standard path, not a
  self-service product.
- **`workflow_dispatch`:** Workflow trigger design is outside the minimum
  deployment path.
- **Image automation:** Image updates remain fixed and manually committed after
  validation in this version.
- **GitOps PR automation:** Automatically creating GitOps pull requests is
  outside the fixed-tag workflow.
- **Trivy:** Image security scanning is not required to demonstrate
  reproducible local GitOps deployment.
- **Drift self-healing:** Automated drift correction is beyond this initial
  deployment foundation.
- **Rollback automation:** Automated recovery is not needed to verify the
  first deployment path.
- **Cloud infrastructure:** Local kind is the v0.1.0 execution environment.
- **Remote state:** No cloud infrastructure state exists within this scope.
- **Monitoring:** Operational telemetry is not required to prove deployment
  standardization.
- **HPA:** One fixed replica proves the path without adding scaling behavior.
- **NetworkPolicy:** Advanced traffic restriction is unnecessary for one local
  workload.
- **Vault:** Secret lifecycle management is not the primary problem addressed
  by this project.
- **Backstage:** An internal developer portal is outside the single deployment
  route.
- **Service mesh:** One workload does not need service-to-service traffic
  management.
- **Crossplane:** Infrastructure abstraction is outside the minimum viable
  platform.
- **Operators:** Custom Kubernetes control loops are unnecessary for the
  declared workload.
- **Multiple clusters or clouds:** The objective is deployment
  standardization, not fleet management.
- **Databases:** Service A is only an HTTP deployment demonstration.
- **Authentication:** User authentication is not needed to validate this
  deployment flow.
- **REST APIs:** The platform is not a new backend service.
- **AI features:** They do not contribute to the deterministic deployment
  foundation.
- **Production-readiness claims:** Local kind verification is not production
  qualification.
