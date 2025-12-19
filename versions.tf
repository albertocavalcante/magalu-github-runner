terraform {
  required_version = ">= 1.11.0"

  required_providers {
    mgc = {
      source  = "magalucloud/mgc"
      version = ">= 0.18.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
