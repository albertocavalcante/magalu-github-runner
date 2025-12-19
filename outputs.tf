output "runner_names" {
  description = "The names of the created runner instances."
  value       = mgc_virtual_machine_instances.runner[*].name
}

output "runner_public_ips" {
  description = "The public IP addresses of the runners."
  value       = mgc_virtual_machine_instances.runner[*].ipv4
}

output "runner_ids" {
  description = "The IDs of the created runner instances."
  value       = mgc_virtual_machine_instances.runner[*].id
}

output "generated_ssh_private_key" {
  description = "The generated SSH private key if create_ssh_key is true. SENSITIVE."
  value       = var.create_ssh_key && var.ssh_key_name == null ? tls_private_key.ssh[0].private_key_pem : null
  sensitive   = true
}
