output "kms-keys" {
  value = module.kms.keys["gke-key"]
}
