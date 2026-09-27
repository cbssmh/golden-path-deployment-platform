# Repository responsibilities

Platform operators change the Platform repository to bootstrap or verify a
local cluster and to define the bootstrap AppProjects. Platform-owned paths in
the GitOps repository define all AppProjects and Applications, Namespace
`dev`, `ServiceAccount/service-a`, ResourceQuota, LimitRange, the
ValidatingAdmissionPolicy, and its binding. Workload-owned paths define only
Service A's Deployment, Service, and ConfigMap.

Application developers change the Example Services repository to alter
Service A and build its container image. Its publisher creates a
multi-architecture image only after `test-and-build`. A separately reviewed
OCI digest is manually committed to GitOps; publishing does not automate a
GitOps update or pull request.

CODEOWNERS documents these path responsibilities but does not provide
independent review while one maintainer owns all paths. Runtime enforcement is
provided by AppProjects, PSA, ResourceQuota, LimitRange, and the admission
policy according to their separate scopes. Active GitHub rulesets enforce the
pull-request and CI workflows. The released VAP binding remains Warn/Audit.
