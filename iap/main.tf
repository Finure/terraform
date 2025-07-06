terraform {
  backend "gcs" {
    prefix       = "iap"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

data "terraform_remote_state" "network" {
  backend = "gcs"
  config = {
    bucket = var.terraform_bucket
    prefix = "network"
  }
}

locals {
  bastion_name = format("%s-iap", var.cluster_name)
  bastion_zone = format("%s-a", var.region)
}

module "bastion" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "~> 8.0"

  network        = data.terraform_remote_state.network.outputs.network_self_link
  subnet         = data.terraform_remote_state.network.outputs.subnets_self_links
  project        = var.project_id
  host_project   = var.project_id
  name           = local.bastion_name
  zone           = local.bastion_zone
  image_project  = "debian-cloud"
  machine_type   = "e2-small"
  startup_script = templatefile("${path.module}/templates/startup-script.tfpl", {})
  members        = var.bastion_members
  shielded_vm    = "false"

  service_account_roles = ["roles/container.viewer"]
}
