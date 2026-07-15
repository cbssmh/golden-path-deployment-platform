# Repository responsibilities

Platform operators change the Platform repository to bootstrap or verify a
local cluster. Delivery operators change the GitOps repository to alter
Kubernetes desired state. Application developers change the Example Services
repository to alter Service A and its container image. A fixed image tag is
manually committed to GitOps after validation; there is no automated GitOps
update or PR.
