/**
 * variables.tf
 *
 * Defines the input variables for the Magalu Cloud GitHub Runner module.
 * These inputs configure authentication, runner count, machine specifications, and networking.
 */

variable "github_repository_url" {
  description = "The full URL of the GitHub repository where the runners will be registered. (e.g., https://github.com/my-org/my-repo)"
  type        = string

  validation {
    condition     = can(regex("^https://github.com/", var.github_repository_url))
    error_message = "The repository URL must start with 'https://github.com/'."
  }
}

variable "github_personal_access_token" {
  description = "A GitHub Personal Access Token (PAT) with 'repo' scope (or 'admin:org' for organization runners). This is used to dynamically generate runner registration tokens."
  type        = string
  sensitive   = true
}

variable "runner_count" {
  description = "The number of runner instances to provision."
  type        = number
  default     = 1

  validation {
    condition     = var.runner_count > 0
    error_message = "The runner_count must be at least 1."
  }
}

variable "machine_type" {
  description = "The Magalu Cloud machine type (flavor) for the runner instances. Defaults to 'BV1-1-40'."
  type        = string
  default     = "BV1-1-40"
}

variable "image" {
  description = "The operating system image name. The included startup script supports Ubuntu, Debian, Rocky Linux, and AlmaLinux."
  type        = string
  default     = "cloud-ubuntu-22.04 LTS"
}

variable "runner_name_prefix" {
  description = "A prefix string used for naming the runner resources and generating unique identifiers."
  type        = string
  default     = "mgc-runner"
}

variable "runner_labels" {
  description = "A list of custom labels to apply to the GitHub self-hosted runner for job targeting."
  type        = list(string)
  default     = []
}

variable "ssh_key_name" {
  description = "The name of a pre-existing SSH key in Magalu Cloud to attach to the runner VMs. If not provided and 'create_ssh_key' is true, a new key will be generated."
  type        = string
  default     = null
}

variable "create_ssh_key" {
  description = "If true, generates a new SSH key pair when 'ssh_key_name' is not provided. The private key will be outputted."
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "The specific Magalu Cloud Availability Zone to deploy the runners into. If null, the cloud provider automatic selection applies."
  type        = string
  default     = null
}
