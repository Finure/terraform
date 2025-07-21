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
  
  raw_kms_accounts = flatten([
    for app_name, app in local.apps_config : [
      for project in try(app.service_accounts, []) : [
        for role_string in try(project.kmsroles, []) : merge(project, {
          app                = app_name
          role               = length(split(":", role_string)) == 2 ? split(":", role_string)[0] : ""
          kms_key            = length(split(":", role_string)) == 2 ? split(":", role_string)[1] : ""
          service_account_id = (
            length(regexall(".*@.*", try(project.account_id, ""))) > 0
              ? try(project.account_id, "")
              : "${try(project.account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
          )
          account_id         = project.account_id 
        })
      ]
    ]
  ])

  kms_accounts = [
    for acct in local.raw_kms_accounts : acct
    if acct.role != "" && acct.kms_key != ""
  ]

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

  project_accounts = flatten([
    for app_name, app in local.apps_config : [
      for project in try(app.service_accounts, []) : [
        for role in try(project.roles, []) : merge(project, {
          app                = app_name
          role               = role
          service_account_id = (
            length(regexall(".*@.*", try(project.account_id, ""))) > 0
              ? try(project.account_id, "")
              : "${try(project.account_id, "")}@${var.project_id}.iam.gserviceaccount.com"
          )
        })
      ]
    ]
  ])
}
