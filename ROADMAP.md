# Roadmap

Future plans for the Magalu Cloud GitHub Runner module.

## Phase 1: MVP (Current)
- [x] Static VM instances via Terraform `count`.
- [x] Personal Access Token (PAT) authentication.
- [x] Bash-based `user_data` script (Distro-agnostic: apt/yum/dnf).
- [x] Basic networking (Public IP attachment).

## Phase 2: Reliability & Hardening
- [ ] **Systemd Hardening**: Improve service definition (restart policies, limits).
- [ ] **Log Rotation**: Configure `logrotate` for runner logs.
- [ ] **Security**: Minimal IAM permissions (once IAM is fully exposed via Terraform).
- [ ] **Ephemeral Mode**: Support flags for `--ephemeral` runners (requires easy replacement logic).

## Phase 3: Autoscaling (The "Controller" Phase)
> Since Magalu Cloud does not have a native Auto Scaling Group (ASG) or Queue service (SQS), we need a custom solution.

- [ ] **Custom Controller**: precise Go/Python service to:
    - Listen to GitHub Webhooks.
    - Call Magalu API to Create/Delete VMs based on queue depth.
- [ ] **Interim Solution**: Scheduled Cron jobs to scale up/down based on time of day (e.g., business hours).

## Phase 4: Authentication Security
- [ ] **GitHub Apps**: Replace PAT with GitHub App private key authentication.
    - Implement a small helper (Go binary or script) to exchange App Key for Installation Token inside the runner.

## Phase 5: Kubernetes Support
- [ ] **MKS Support**: Helm chart or Operator to run ephemeral runners as Pods.
    - Leverage [Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller).
