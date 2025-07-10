terraform {
  backend "gcs" {
    prefix       = "iam"
    use_lockfile = true
  }
}

provider "google" {
  default_labels = {
    project     = "finure"
    provisioned = "terraform"
  }
}

resource "google_service_account" "service-account" {
  for_each = { for service_account in local.service_accounts : "${service_account.app}:${service_account.account_id}" => service_account }

  account_id   = each.value.account_id
  display_name = each.value.display_name
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "storage-bucket-iam-member" {
  for_each = { for storage_bucket in local.storage_buckets : "${storage_bucket.app}:${storage_bucket.name}" => storage_bucket }

  bucket     = each.value.name
  role       = each.value.role
  member     = try(each.value.member, "serviceAccount:${each.value.service_account_id}")
  depends_on = [google_service_account.service-account]
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = { for service_account in local.service_accounts : "${service_account.app}:${service_account.account_id}" => service_account }
  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.value.service_account_id}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.ns}/${each.value.kubernetes_service_account}]"
  depends_on = [ google_service_account.service-account ]
}
