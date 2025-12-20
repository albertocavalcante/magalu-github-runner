/**
 * main.tf
 *
 * Core module logic. Provisions Virtual Machines on Magalu Cloud and injects
 * the startup script to configure them as ephemeral GitHub Actions runners.
 */

# Generates a random suffix to ensure unique naming for runner instances.
resource "random_id" "runner_id" {
  count       = var.runner_count
  byte_length = 4
  prefix      = "${var.runner_name_prefix}-"
}

# ---------------------------------------------------------------------------------------------------------------------
# SSH KEY GENERATION (OPTIONAL)
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ssh" {
  count     = var.ssh_key_name == null && var.create_ssh_key ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "mgc_ssh_keys" "ssh" {
  count = var.ssh_key_name == null && var.create_ssh_key ? 1 : 0
  name  = "${var.runner_name_prefix}-ssh-key-${random_id.runner_id[0].hex}"
  key   = tls_private_key.ssh[0].public_key_openssh
}

# Provisions the Virtual Machine instances.
resource "mgc_virtual_machine_instances" "runner" {
  count = var.runner_count

  name              = random_id.runner_id[count.index].hex
  machine_type      = var.machine_type
  image             = var.image
  availability_zone = var.availability_zone

  ssh_key_name = var.ssh_key_name != null ? var.ssh_key_name : (var.create_ssh_key ? mgc_ssh_keys.ssh[0].name : null)

  # WARNING: allocate_public_ipv4 creates IPs that are NOT deleted when the VM is destroyed.
  # This is documented MGC provider behavior - public IPs remain allocated to your tenant.
  # Run ./scripts/cleanup-orphans.sh periodically to remove orphaned IPs.
  #
  # ARCHITECTURE NOTE: GitHub Actions runners use OUTBOUND-ONLY long-polling to GitHub.
  # A public IP is NOT required for runner functionality - only for SSH troubleshooting.
  # The runner polls github.com/actions.githubusercontent.com (HTTPS:443) for jobs.
  #
  # TODO: Consider defaulting to false and using NAT gateway for outbound connectivity.
  # This would eliminate orphaned IP issues entirely. Keep true for now for SSH debugging.
  #
  # Allocate a public IP to ensure the runner can communicate outbound to GitHub APIs.
  allocate_public_ipv4 = true

  # Inject the startup script, rendering essential variables like the PAT and Repo URL.
  user_data = base64encode(templatefile("${path.module}/templates/startup.sh.tftpl", {
    github_repository_url        = var.github_repository_url
    github_personal_access_token = var.github_personal_access_token
    runner_name                  = random_id.runner_id[count.index].hex
    runner_labels                = join(",", var.runner_labels)
  }))

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data]
  }
}
