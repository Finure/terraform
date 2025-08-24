terraform {
  backend "gcs" {
    prefix       = "gke"
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

data "terraform_remote_state" "iap" {
  backend = "gcs"
  config = {
    bucket = var.terraform_bucket
    prefix = "iap"
  }
}

data "terraform_remote_state" "kms" {
  backend = "gcs"
  config = {
    bucket = var.terraform_bucket
    prefix = "kms"
  }
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/safer-cluster"
  version = "~> 37.0"

  project_id                  = var.project_id
  name                        = var.cluster_name
  region                      = var.region
  zones                       = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                     = data.terraform_remote_state.network.outputs.network_name
  subnetwork                  = data.terraform_remote_state.network.outputs.subnets_names
  ip_range_pods               = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_name_pods
  ip_range_services           = data.terraform_remote_state.network.outputs.subnets_secondary_ranges_name_svc
  http_load_balancing         = true
  horizontal_pod_autoscaling  = true
  create_service_account      = true
  dns_cache                   = true
  enable_intranode_visibility = true
  enable_private_endpoint     = true
  deletion_protection         = false
  initial_node_count          = 1
  release_channel             = "UNSPECIFIED"
  master_authorized_networks = [{
    cidr_block   = "${data.terraform_remote_state.iap.outputs.iap_ip}/32"
    display_name = "IAP"
  }]
  database_encryption = [
    {
      "key_name" : data.terraform_remote_state.kms.outputs.kms-keys,
      "state" : "ENCRYPTED"
    }
  ]
  node_pools_labels = {
    all = {
      project     = "finure"
      provisioned = "terraform"
    }
  }
  grant_registry_access = true
  node_pools = [
    {
      name          = "default"
      min_count     = 1
      max_count     = 3
      auto_upgrade  = false
      node_metadata = "GKE_METADATA"
      image_type    = "COS_CONTAINERD"
      disk_type     = "pd-standard"
      machine_type  = "e2-standard-4"
      disk_size_gb  = 500
      auto_repair   = true
      autoscaling   = true
    }
  ]
}

resource "null_resource" "patch_kubeconfig" {
  depends_on = [module.gke]

  provisioner "local-exec" {
    command = <<-EOT
      KUBECONFIG_PATH="$HOME/.kube/config"
      # Optional
      if [ -f "$KUBECONFIG_PATH" ]; then
        echo "Removing existing kubeconfig at $KUBECONFIG_PATH"
        rm "$KUBECONFIG_PATH"
      fi

      # Fetch GKE credentials
      gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id} --internal-ip

      # Run IAP tunnel
      gcloud compute ssh ${data.terraform_remote_state.iap.outputs.iap_hostname} --tunnel-through-iap --project ${var.project_id} --zone ${data.terraform_remote_state.iap.outputs.iap_zone} -- -L11001:127.0.0.1:11001 -N -q -f > /tmp/iap-tunnel.log 2>&1 &
      disown

      # Add proxy-url to context
      CONTEXT=$(kubectl config current-context)
      CLUSTER=$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'"$CONTEXT"'")].context.cluster}')
      kubectl config set-cluster "$CLUSTER" --proxy-url=http://127.0.0.1:11001
      echo "Done"
    EOT
  }
}
