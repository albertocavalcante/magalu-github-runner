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
| `docker: permission denied` | User not in docker group | Restart VM or destroy/recreate |
| Runner not appearing in GitHub | Script failed early | Check cloud-init logs for errors |
| `dnf config-manager: command not found` | Missing `dnf-plugins-core` | Ensure it's in system dependencies |

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
