# Troubleshooting

This is a living document of debugging tactics and known issues discovered while operating GitHub Actions runners on Magalu Cloud.

## Connecting to a Runner VM

When a runner fails to come online, SSH into the VM to diagnose issues.

```bash
# Get the SSH key (if using create_ssh_key = true)
terraform output -raw generated_ssh_private_key > runner-key.pem
chmod 600 runner-key.pem

# Get the runner IP
terraform output runner_ipv4s

# Connect (use ubuntu/rocky/debian depending on image)
ssh -i runner-key.pem ubuntu@<IP>      # Ubuntu/Debian
ssh -i runner-key.pem rocky@<IP>       # Rocky Linux
ssh -i runner-key.pem opc@<IP>         # Oracle Linux
```

## Common Diagnostic Commands

```bash
# Check cloud-init status and logs
cloud-init status
sudo tail -100 /var/log/cloud-init-output.log

# Check if runner user and service exist
id github-runner
sudo ls -la /home/github-runner/actions-runner/
systemctl status 'actions.runner.*'

# Check Docker installation
docker --version
sudo docker ps
groups github-runner  # Should include 'docker'

# Check user group membership
groups github-runner  # Should include: wheel (RHEL) or sudo (Debian), docker
```

## Known Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `usermod: group 'sudo' does not exist` | RHEL-based distros use `wheel` group | Fixed in v0.2.0+ |
| `status=203/EXEC` / `Permission denied` | SELinux `user_home_t` context blocking systemd | Fixed by `chcon -t bin_t` in startup script |
| `docker: permission denied` | User not in docker group | Restart VM or destroy/recreate |
| Runner not appearing in GitHub | Script failed early | Check cloud-init logs for errors |
| `dnf config-manager: command not found` | Missing `dnf-plugins-core` | Ensure it's in system dependencies |
| No available public IP addresses | Orphaned IPs exhausting quota | Run cleanup script (see below) |

## Resource Quota Exhaustion

### Symptom

```
Error: No available public IP addresses for allocation or network-interface in your account
```

### Root Cause

The MGC provider **does not delete public IPs** when VMs are destroyed. This is documented behavior:

> "A Public IPv4 address resource will be created and associated with your tenant, when deleting the instance the Public IPv4 will not be deleted and charges may apply."

This causes orphaned IPs to accumulate, eventually exhausting your account quota.

### Fix

Use the cleanup script to remove orphaned resources:

```bash
# Dry run first (shows what would be deleted)
./scripts/cleanup-orphans.sh --region br-ne1 --dry-run

# Actually delete orphaned public IPs
./scripts/cleanup-orphans.sh --region br-ne1 --execute

# Also clean SSH keys and VMs (be careful!)
./scripts/cleanup-orphans.sh --region br-ne1 --execute --ssh-keys --vms
```

### Prevention

Consider running the cleanup script periodically, or as part of your CI teardown process.

## Deep Dive: Investigating Script Failures

If the runner service isn't running, trace through the startup script stages:

```bash
# 1. Was the script even executed?
sudo cat /var/log/cloud-init-output.log | head -50

# 2. Check for specific error patterns
sudo grep -i "error\|fail\|denied" /var/log/cloud-init-output.log

# 3. Verify Docker is running
sudo systemctl status docker

# 4. Check if runner was downloaded and configured
sudo ls -la /home/github-runner/actions-runner/

# 5. Check runner service logs (if it exists)
sudo journalctl -u 'actions.runner.*' --no-pager
```

## Contributing

When you discover a new issue and its fix, please add it to this document to help future troubleshooting efforts.
