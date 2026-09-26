# Repository responsibilities

Platform operators change the Platform repository to bootstrap or verify a
local cluster and to define the bootstrap AppProjects. Platform-owned paths in
the GitOps repository define the workload AppProject, Namespace, and child
Application. Workload-owned paths define Service A's Deployment, Service, and
ConfigMap. Application developers change the Example Services repository to
alter Service A and its container image. A validated image digest is manually
committed to GitOps; there is no automated GitOps update or PR.

CODEOWNERS documents these path responsibilities but does not provide
independent review while one maintainer owns all paths. Runtime enforcement is
provided by AppProjects; the active GitHub rulesets separately enforce the
pull-request and CI workflow.
