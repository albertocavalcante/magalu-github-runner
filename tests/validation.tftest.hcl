# TDD: Validate Input Logic

# Mock the Magalu Cloud provider since we don't have real credentials in tests
mock_provider "mgc" {}

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

# -----------------------------------------------------------------------------
# Negative Tests: Invalid Inputs Should Fail Validation
# -----------------------------------------------------------------------------

run "invalid_image_fails" {
  command = plan

  variables {
    image = "invalid-distro"
  }

  expect_failures = [
    var.image
  ]
}

run "invalid_machine_type_fails" {
  command = plan

  variables {
    machine_type = "invalid-type"
  }

  expect_failures = [
    var.machine_type
  ]
}

run "invalid_availability_zone_fails" {
  command = plan

  variables {
    availability_zone = "us-east-1a"
  }

  expect_failures = [
    var.availability_zone
  ]
}

run "valid_availability_zone_passes" {
  command = plan

  variables {
    availability_zone = "br-se1-a"
  }

  # No expect_failures means we expect this to pass
  assert {
    condition     = var.availability_zone == "br-se1-a"
    error_message = "Valid AZ should be accepted"
  }
}

run "null_availability_zone_passes" {
  command = plan

  variables {
    availability_zone = null
  }

  assert {
    condition     = var.availability_zone == null
    error_message = "Null AZ should be accepted"
  }
}
