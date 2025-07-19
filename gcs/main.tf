terraform {
  backend "gcs" {
    prefix       = "gcs"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

resource "google_storage_bucket" "buckets" {
  for_each = toset(var.buckets)

  name                        = each.value
  location                    = "US"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true
  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = ["STANDARD"]
      with_state            = "ANY"
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  lifecycle_rule {
    condition {
      age                   = 90
      matches_storage_class = ["NEARLINE"]
    }
    action {
      type = "Delete"
    }
  }
  soft_delete_policy {
    retention_duration_seconds = 0
  }
  project = var.project_id
}
