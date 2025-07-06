terraform {
  backend "gcs" {
    prefix       = "kms"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

resource "random_string" "kms" {
  length  = 6
  special = false
}

locals {
  kms_name = "kms-${random_string.kms.result}"
}

module "kms" {
  source          = "terraform-google-modules/kms/google"
  version         = "~> 4.0"
  project_id      = var.project_id
  location        = var.region
  keyring         = local.kms_name
  keys            = ["gke-key"]
  prevent_destroy = false
}
