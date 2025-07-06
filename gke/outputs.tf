output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = module.gke.endpoint
}

output "endpoint_dns" {
  sensitive   = true
  description = "Cluster endpoint DNS"
  value       = module.gke.endpoint_dns
}

output "gke_credentials" {
  description = "Run this command to add the cluster context to your kube config"
  value       = format("gcloud container clusters get-credentials %s --region %s --project %s --internal-ip", var.cluster_name, var.region, var.project_id)
}

output "iap_ssh_command" {
  description = "Run this command to port forward to the bastion host command"
  value       = format("gcloud compute ssh %s --tunnel-through-iap --project %s --zone %s -- -L11001:127.0.0.1:11001 -N -q -f", data.terraform_remote_state.iap.outputs.iap_hostname, var.project_id, data.terraform_remote_state.iap.outputs.iap_zone)
}
