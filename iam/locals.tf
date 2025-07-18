locals {
  apps_config = yamldecode(file("${path.module}/apps.yaml"))

  service_accounts = flatten([
    for app_name, app in local.apps_config :
    [
      for sa in try(app.service_accounts, []) : merge(sa, {
        app                = app_name
        service_account_id = length(regexall(".*@.*", try(sa.account_id, ""))) > 0 ? try(sa.account_id, "") : "${try(sa.account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
      })
    ]
  ])

  service_account_kms_ops = { for service_account in local.service_accounts : service_account.app => {
    app                = service_account.app
    account_id         = service_account.account_id
    service_account_id = service_account.service_account_id
    kmsops             = service_account.kmsops
    display_name       = service_account.display_name
    }
  if try(service_account.kmsops, null) != null }

  service_account_kms_viewer = { for service_account in local.service_accounts : service_account.app => {
    app                = service_account.app
    account_id         = service_account.account_id
    service_account_id = service_account.service_account_id
    kmsviewer          = service_account.kmsviewer
    display_name       = service_account.display_name
    }
  if try(service_account.kmsviewer, null) != null }

  storage_buckets = flatten([
    for app_name, app in local.apps_config :
    [
      for bucket in try(app.storage_buckets, []) :
      merge(
        bucket,
        {
          app                = try(bucket.member, app_name)
          service_account_id = length(regexall(".*@.*", try(bucket.service_account_id, ""))) > 0 ? try(bucket.service_account_id, "") : "${try(bucket.service_account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
        }
      )
    ]
  ])
  bigquery_datasets = flatten([
    for app_name, app in local.apps_config : [
      for bq in try(app.bigquery, []) : merge(
        bq,
        {
          app = app_name
          service_account_id = (
            length(regexall("@", bq.service_account_id)) > 0 ?
            bq.service_account_id :
            "${bq.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
          )
        }
      )
    ]
  ])
  compute_accounts = flatten([
    for app_name, app in local.apps_config :
    [
      for compute in try(app.compute, []) : merge(compute, {
        app                = app_name
        service_account_id = length(regexall(".*@.*", try(compute.account_id, ""))) > 0 ? try(compute.account_id, "") : "${try(compute.account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
      })
    ]
  ])

  bigquery_job_users = flatten([
    for app_name, app in local.apps_config :
    [
      for bigquery in try(app.bigqueryProject, []) : merge(bigquery, {
        app                = app_name
        service_account_id = length(regexall(".*@.*", try(bigquery.account_id, ""))) > 0 ? try(bigquery.account_id, "") : "${try(bigquery.account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
      })
    ]
  ])
}
