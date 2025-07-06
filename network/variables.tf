variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in"
}

variable "region" {
  type        = string
  description = "The region to host the cluster in"
}

variable "network_name" {
  type        = string
  description = "The name of the network being created to host the cluster in"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet being created to host the cluster in"
}

variable "subnet_ip" {
  type        = string
  description = "The cidr range of the subnet"
}

variable "ip_range_pods_name" {
  type        = string
  description = "The secondary ip range to use for pods"
}

variable "ip_range_services_name" {
  type        = string
  description = "The secondary ip range to use for pods"
}

variable "terraform_bucket" {
  type    = string
  default = "The name of the bucket containing the terraform state files"
}