output "runner_names" {
  description = "The names of the created runner instances."
  value       = mgc_virtual_machine_instances.runner[*].name
}

output "runner_public_ips" {
  description = "The public IP addresses of the runners."
  value       = mgc_virtual_machine_instances.runner[*].network_interface[0].public_ip
}

output "runner_ids" {
  description = "The IDs of the created runner instances."
  value       = mgc_virtual_machine_instances.runner[*].id
}
