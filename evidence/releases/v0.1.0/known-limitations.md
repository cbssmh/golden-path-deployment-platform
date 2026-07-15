# Known limitations

Runtime Kubernetes evidence has not yet been collected because the public
GitOps repository has not been created and populated. kind is installed,
Docker daemon access was verified, and the Service A container image built
successfully. The committed configuration targets the public GitOps
repository and cannot sync until that repository exists. No secrets, tokens,
or Argo CD passwords are stored here.
