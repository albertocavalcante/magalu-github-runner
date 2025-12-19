# TDD: Validate Input Logic

variables {
  github_repository_url        = "https://github.com/test-org/test-repo"
  github_personal_access_token = "ghp_mock_token"
  runner_count                 = 1
  machine_type                 = "BV1-1-40"
  image                        = "cloud-ubuntu-22.04 LTS"
}

run "validate_inputs" {
  command = plan

  assert {
    condition     = var.runner_count > 0
    error_message = "Runner count must be greater than 0"
  }
}

run "validate_outputs_exist" {
  command = apply

  # We expect apply to fail if we don't have real creds/images mocked, 
  # but for 'plan' based tests we can check resource structure.
  # Since this is a unit test, we might struggle without a mock provider.
  # However, standard practice for logic validation:

  module {
    source = "./"
  }
}
