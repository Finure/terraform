variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in"
}

variable "terraform_bucket" {
  type    = string
  default = "The name of the bucket containing the terraform state files"
}

