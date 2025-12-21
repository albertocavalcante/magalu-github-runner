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


## Diagnosing Runtime Crashes (Job Killed)

If a job starts but suddenly stops or the runner service dies:

1. **Check for Out-Of-Memory (OOM) Kills**:
   This is the most common cause for "Killed" messages.
   ```bash
   sudo dmesg | grep -i "kill"
   # OR
   sudo grep -i "Out of memory" /var/log/messages
   ```

2. **Runner Application Logs**:
   The runner logs detailed execution info to the `_diag` folder.
   ```bash
   # List logs by time
   sudo ls -ltr /home/github-runner/actions-runner/_diag/
   
   # View the latest Worker log (handles the job execution)
   sudo tail -f /home/github-runner/actions-runner/_diag/Worker_*.log
   
   # View the latest Runner log (handles network/connection)
   sudo tail -f /home/github-runner/actions-runner/_diag/Runner_*.log
   ```

3. **Service Status**:
   ```bash
   sudo systemctl status actions.runner.*
   sudo journalctl -u actions.runner.* -n 50 --no-pager
   ```

## Diagnosing Hung CI Jobs (Timeouts)

If a job runs "forever" until it hits the 6-hour (or custom) timeout, it usually indicates a **process hang** or **thread starvation**, not a runner crash.

### 1. Identify the Failure Reason

Use the GitHub CLI (`gh`) to check the run status.
```bash
# View summary of the run
gh run view <RUN_ID> --repo <OWNER/REPO>

# Example Output:
# X The action 'Run Unit Tests' has timed out after 20 minutes.
```

### 2. Retrieve the Logs

**Standard Failed Logs** (`--log-failed`) are often insufficient because they only show the *error* (the timeout message) and miss the *cause* (what happened right before).

**Method: Get Full Job Logs**
1.  Find the Job ID from `gh run view`.
2.  Download the full log.
    ```bash
    gh run view --repo <OWNER/REPO> --job <JOB_ID> --log > job_log.txt
    ```
3.  Inspect the end of the log to find the last executing step.
    ```bash
    tail -n 100 job_log.txt
    ```

### 3. Analyze for Deadlocks (Thread Starvation)

If the log stops abruptly in the middle of a test suite (e.g., during "Concurrent Tests"):

*   **Symptom**: The runner is active (heartbeat ok), but the job is stuck.
*   **Cause**: On small runners (`BV1-1-40` with 1 vCPU), using `Dispatchers.Default` (Kotlin) or `ForkJoinPool` (Java) provides very few threads (often 1 or 2).
*   **Mechanism**: If your tests launch multiple blocking tasks (coroutines calling `.get()` or `await`), they can consume all available threads. If the task they are waiting for *also* needs a thread to run, you get a **deadlock**.
*   **Fix**:
    *   **Upgrade Runner**: Use a machine with 2+ vCPUs to increase the thread pool size.
    *   **Refactor Code**: Avoid blocking calls inside common pools; use `Dispatchers.IO` or true non-blocking suspension.

## Contributing

When you discover a new issue and its fix, please add it to this document to help future troubleshooting efforts.
