# Platform rebuild runbook

With `config/platform.env.local` configured for a reachable public GitOps
repository, run:

```bash
make destroy
make bootstrap
make verify
make destroy
make bootstrap
make verify
```

After each verification, collect the commands listed in
`docs/verification-guide.md` without recording secrets, tokens, or Argo CD
administrator passwords. If a run fails, retain the command output in
`evidence/releases/v0.1.0/` and record the failure rather than claiming
success.
