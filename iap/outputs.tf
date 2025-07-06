output "iap_ip" {
  value = module.bastion.ip_address
}

output "iap_hostname" {
  value = module.bastion.hostname
}

output "iap_zone" {
  value = local.bastion_zone
}
