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

resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each           = { for service_account in local.service_accounts : "${service_account.app}:${service_account.account_id}" => service_account }
  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.value.service_account_id}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value.ns}/${each.value.kubernetes_service_account}]"
  depends_on         = [google_service_account.service-account]
}

resource "google_storage_bucket_iam_member" "storage-bucket-iam-member" {
  for_each = { for storage_bucket in local.storage_buckets : "${storage_bucket.app}:${storage_bucket.name}" => storage_bucket }

  bucket     = each.value.name
  role       = each.value.role
  member     = try(each.value.member, "serviceAccount:${each.value.service_account_id}")
  depends_on = [google_service_account.service-account]
}

resource "google_kms_crypto_key_iam_member" "kms_key_viewer_iam_member" {
  for_each      = local.service_account_kms_viewer
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/${var.kms_key_ring}/cryptoKeys/${each.value.kmsviewer}"
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${each.value.service_account_id}"
  depends_on    = [google_service_account.service-account]
}

resource "google_kms_crypto_key_iam_member" "kms_key_ops_iam_member" {
  for_each      = local.service_account_kms_ops
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/${var.kms_key_ring}/cryptoKeys/${each.value.kmsops}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value.service_account_id}"
  depends_on    = [google_service_account.service-account]
}

resource "google_bigquery_dataset_iam_member" "bq_dataset_iam_member" {
  for_each = {
    for bq in local.bigquery_datasets :
    "${bq.app}:${bq.name}:${bq.role}:${bq.service_account_id}" => bq
  }
  project    = var.project_id
  dataset_id = each.value.name
  role       = each.value.role
  member     = "serviceAccount:${each.value.service_account_id}"
  depends_on = [google_service_account.service-account]
}

resource "google_project_iam_member" "compute_viewer" {
  for_each   = { for compute_account in local.compute_accounts : "${compute_account.app}:${compute_account.account_id}" => compute_account }
  project    = var.project_id
  role       = "roles/compute.viewer"
  member     = "serviceAccount:${each.value.service_account_id}"
  depends_on = [google_service_account.service-account]
}

resource "google_project_iam_member" "iam_admin" {
  for_each   = { for iam_account in local.iam_accounts : "${iam_account.app}:${iam_account.account_id}" => iam_account }
  project    = var.project_id
  role       = "roles/resourcemanager.projectIamAdmin"
  member     = "serviceAccount:${each.value.service_account_id}"
  depends_on = [google_service_account.service-account]
}

resource "google_project_iam_member" "service_account_admin" {
  for_each   = { for iam_account in local.iam_accounts : "${iam_account.app}:${iam_account.account_id}" => iam_account }
  project    = var.project_id
  role       = "roles/iam.serviceAccountAdmin"
  member     = "serviceAccount:${each.value.service_account_id}"
  depends_on = [google_service_account.service-account]
}

resource "google_project_iam_member" "bq_job_user" {
  for_each   = { for bigquery_job_user in local.bigquery_job_users : "${bigquery_job_user.app}:${bigquery_job_user.account_id}" => bigquery_job_user }
  project    = var.project_id
  role       = "roles/bigquery.jobUser"
  member     = "serviceAccount:${each.value.service_account_id}"
  depends_on = [google_service_account.service-account]
}
