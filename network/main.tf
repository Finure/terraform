terraform {
  backend "gcs" {
    prefix       = "network"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

data "terraform_remote_state" "api" {
  backend = "gcs"
  config = {
    bucket = var.terraform_bucket
    prefix = "api"
  }
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.0"

  project_id              = var.project_id
  network_name            = var.network_name
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
  subnets = [
    {
      subnet_name           = var.subnet_name
      subnet_ip             = var.subnet_ip
      subnet_region         = var.region
      subnet_private_access = true
      subnet_flow_logs      = true
      description           = "This subnet is managed by Terraform"
    }
  ]
  secondary_ranges = {
    (var.subnet_name) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "~> 5.0"
  project_id    = var.project_id
  region        = var.region
  router        = "nat-router"
  network       = module.vpc.network_self_link
  create_router = true
}
