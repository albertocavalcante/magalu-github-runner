# Magalu Cloud GitHub Runner Module

Terraform module to deploy self-hosted GitHub Actions runners on Magalu Cloud (MGC) using Virtual Machines.

> **Status**: MVP (Minimum Viable Product). Supports static VM instances with Personal Access Token (PAT) authentication.

## Features

- **Distro-Agnostic**: Supports Ubuntu, Debian, Rocky Linux, AlmaLinux (auto-detects package manager).
- **Simple Architecture**: Static VMs managed by Terraform `count`.
- **User Data**: Automated startup script to install dependencies, create user, and register runner.
- **Networking**: Configurable public IP attachment.

## Usage

```hcl
module "gh_runner" {
  source = "git::https://github.com/albertocavalcante/magalu-github-runner.git"

  github_repository_url      = "https://github.com/my-org/my-repo"
  github_personal_access_token = var.gh_pat
  runner_count               = 2
  machine_type               = "BV1-1-40"
  
  # Image examples: "cloud-ubuntu-22.04 LTS", "cloud-rocky-9"
  image                      = "cloud-ubuntu-22.04 LTS" 
}
```

## Requirements

- Terraform >= 1.0
- `magalucloud/mgc` provider

### API Key Scopes
The API Key used by Terraform requires the following scopes:

| Permission | Description |
|------------|-------------|
| `virtual-machine.read` | Read access to Virtual Machines |
| `virtual-machine.write` | Create/Delete Virtual Machines |
| `network.read` | Read access to Networks/VPCs |
| `network.write` | Attach machines to networks |
| `gdb:ssh-pkey-r` | Read SSH Keys |
| `gdb:ssh-pkey-w` | Create SSH Keys |

## Inputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_mgc"></a> [mgc](#requirement\_mgc) | >= 0.18.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_mgc"></a> [mgc](#provider\_mgc) | 0.41.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Resources

| Name | Type |
|------|------|
| [mgc_ssh_keys.ssh](https://registry.terraform.io/providers/magalucloud/mgc/latest/docs/resources/ssh_keys) | resource |
| [mgc_virtual_machine_instances.runner](https://registry.terraform.io/providers/magalucloud/mgc/latest/docs/resources/virtual_machine_instances) | resource |
| [random_id.runner_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [tls_private_key.ssh](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The specific Magalu Cloud Availability Zone to deploy the runners into. If null, the cloud provider automatic selection applies. | `string` | `null` | no |
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | If true, generates a new SSH key pair when 'ssh\_key\_name' is not provided. The private key will be outputted. | `bool` | `true` | no |
| <a name="input_github_personal_access_token"></a> [github\_personal\_access\_token](#input\_github\_personal\_access\_token) | A GitHub Personal Access Token (PAT) with 'repo' scope (or 'admin:org' for organization runners). This is used to dynamically generate runner registration tokens. | `string` | n/a | yes |
| <a name="input_github_repository_url"></a> [github\_repository\_url](#input\_github\_repository\_url) | The full URL of the GitHub repository where the runners will be registered. (e.g., https://github.com/my-org/my-repo) | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | The operating system image name. The included startup script supports Ubuntu, Debian, Rocky Linux, and AlmaLinux. | `string` | `"cloud-ubuntu-22.04 LTS"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The Magalu Cloud machine type (flavor) for the runner instances. Defaults to 'BV1-1-40'. | `string` | `"BV1-1-40"` | no |
| <a name="input_runner_count"></a> [runner\_count](#input\_runner\_count) | The number of runner instances to provision. | `number` | `1` | no |
| <a name="input_runner_labels"></a> [runner\_labels](#input\_runner\_labels) | A list of custom labels to apply to the GitHub self-hosted runner for job targeting. | `list(string)` | `[]` | no |
| <a name="input_runner_name_prefix"></a> [runner\_name\_prefix](#input\_runner\_name\_prefix) | A prefix string used for naming the runner resources and generating unique identifiers. | `string` | `"mgc-runner"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | The name of a pre-existing SSH key in Magalu Cloud to attach to the runner VMs. If not provided and 'create\_ssh\_key' is true, a new key will be generated. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_generated_ssh_private_key"></a> [generated\_ssh\_private\_key](#output\_generated\_ssh\_private\_key) | The generated SSH private key if create\_ssh\_key is true. SENSITIVE. |
| <a name="output_runner_ids"></a> [runner\_ids](#output\_runner\_ids) | The IDs of the created runner instances. |
| <a name="output_runner_names"></a> [runner\_names](#output\_runner\_names) | The names of the created runner instances. |
| <a name="output_runner_public_ips"></a> [runner\_public\_ips](#output\_runner\_public\_ips) | The public IP addresses of the runners. |
<!-- END_TF_DOCS -->

## Roadmap

See [ROADMAP.md](ROADMAP.md) for future plans.
