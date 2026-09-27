# GP-2A platform/workload GitOps trust boundary

## Evidence state

GP-2A repository manifests are `SOURCE-CONFIRMED`, deterministic policy tests
are `TEST-VERIFIED`, and the Argo CD AppProject allow/deny boundary is
`RUNTIME-VERIFIED`. Platform and GitOps `v0.2.0` remain protected historical
releases. Later phases added distinct Pod security, resource, CI, supply-chain,
and admission controls without broadening the workload AppProject.

The bounded intended claim is:

> Service A is constrained by a dedicated Argo CD AppProject to the approved
> GitOps repository, the dev namespace, and Deployment, Service, and ConfigMap
> desired resources.

This is not a multi-tenant claim and does not make the Argo CD controller
least-privileged.

Runtime evidence showed the allowed Service A Application Synced and Healthy,
with Deployment, Service, and ConfigMap resources present. Alternate
repository, forbidden destination, cluster-resource, Namespace, Secret, and
ServiceAccount fixtures were rejected and their resources were absent.

## Enforcement and ownership

- Runtime enforcement: Argo CD AppProjects.
- Repository workflow enforcement: active rulesets require pull requests and
  CI, with direct pushes, force pushes, and branch deletion blocked.
- Ownership documentation: CODEOWNERS.

CODEOWNERS is not an independent security boundary in the current
single-maintainer model. The sole maintainer can modify every path, required
approvals remain zero, and no independent human review exists.

## GitHub rulesets

These rules are active and were read back through the GitHub API.

For `refs/heads/main` in both Platform and GitOps repositories:

- active enforcement;
- no bypass actors;
- pull request required;
- zero required approvals for the single-maintainer model;
- required CODEOWNER approval disabled;
- required conversation resolution;
- strict required-status-check policy enabled so the branch must be current
  before merge;
- required exact status check `static-validation` for Platform and `validate`
  for GitOps;
- non-fast-forward updates blocked;
- branch deletion blocked.

For `refs/tags/v*` in both repositories:

- active enforcement with no bypass actors;
- update restriction enabled, so existing matching tags cannot be moved;
- deletion restriction enabled;
- creation restriction disabled, so a repository writer can create a new
  release tag through the approved release process;
- `v0.1.1` must never be moved.

## Residual risks

- The Argo application-controller retains cluster-wide, high-trust RBAC.
- A GitHub administrator can change repository governance.
- Compromise of platform-owned paths can change Application and AppProject
  definitions.
- Future AppProject misconfiguration can broaden permissions.
- AppProjects restrict repositories, not repository subpaths.
- A solo maintainer has no independent reviewer.
- Direct cluster-admin mutation remains possible.
- Pod security and resource governance are separate runtime-verified phases;
  they do not reduce the Argo controller's authority.
- No NetworkPolicy is present.
- `selfHeal` remains disabled, so live drift is detected but not automatically
  corrected.
