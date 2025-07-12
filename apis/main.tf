terraform {
  backend "gcs" {
    prefix       = "api"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 18.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_api_identities = [{
    api = "container.googleapis.com",
    roles = ["roles/cloudkms.cryptoKeyDecrypter",
    "roles/cloudkms.cryptoKeyEncrypter"],
  }]

  activate_apis = [
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "containerregistry.googleapis.com",
    "container.googleapis.com",
    "binaryauthorization.googleapis.com",
    "stackdriver.googleapis.com",
    "iap.googleapis.com",
    "cloudkms.googleapis.com",
    "beyondcorp.googleapis.com",
    "certificatemanager.googleapis.com",
  ]
}
