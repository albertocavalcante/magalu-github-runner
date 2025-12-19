terraform {
  required_providers {
    mgc = {
      source = "magalucloud/mgc"
    }
  }
}

provider "mgc" {
  region = "br-ne1"
  # Keys are loaded from environment variables MGC_API_KEY
}

# --- Module Usage ---
module "gh_runner" {
  source = "../../"

  github_repository_url        = var.github_repository_url
  github_personal_access_token = var.github_personal_access_token

  runner_count = 1
  machine_type = "BV1-1-40"

  # Example: Using a custom image or default
  image = "cloud-ubuntu-22.04 LTS"
}

# --- Outputs ---
output "runner_ips" {
  value = module.gh_runner.runner_public_ips
}
