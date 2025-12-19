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

# Provisions the Virtual Machine instances.
resource "mgc_virtual_machine_instances" "runner" {
  count = var.runner_count

  name              = random_id.runner_id[count.index].hex
  machine_type      = var.machine_type
  image             = var.image
  availability_zone = var.availability_zone

  ssh_key_name = var.ssh_key_name

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
