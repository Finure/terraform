output "network_self_link" {
  value = module.vpc.network_self_link
}

output "subnets_self_links" {
  value = module.vpc.subnets_self_links[0]
}

output "network_name" {
  value = module.vpc.network_name
}

output "subnets_names" {
  value = module.vpc.subnets_names[0]
}

output "subnets_secondary_ranges_name_pods" {
  value = module.vpc.subnets_secondary_ranges[0][0].range_name
}

output "subnets_secondary_ranges_name_svc" {
  value = module.vpc.subnets_secondary_ranges[0][1].range_name
}