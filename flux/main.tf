terraform {
  required_version = ">= 1.7.0"
  backend "gcs" {
    prefix       = "flux"
    use_lockfile = true
  }
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
  }
}

data "github_repository" "kubernetes" {
  full_name = "${var.github_org}/${var.github_repository}"
}

resource "flux_bootstrap_git" "kubernetes" {
  depends_on = [data.github_repository.kubernetes]

  embedded_manifests = true
  path               = "clusters/finure"
}
