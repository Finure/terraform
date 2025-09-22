# Finure Terraform repo

Finure terraform repo contains the code to bootstrap the Finure cluster on GCP. The infrastructure includes modules for creating private GKE cluster in a private VPC with Private Google Access (PGA) enabled and Cloud NAT setup, along with a bastion host to run an encrypted TCP tunnel via Identity Aware Proxy (IAP) to access the cluster. It also includes modules for creating necessary GCS buckets, KMS keys, service accounts with necessary IAM roles, and Workload Identity bindings to securely manage access between GCP and the Kubernetes cluster. Lastly, it includes Flux, to commit Flux components to Finure Kubernetes repo and configures the Finure cluster to sync with the same repo. The whole bootstrap process is automated using a Makefile to simplify the commands and uses Checkov to validate the Terraform code for security and best practices.

## Prerequisites
- A GCP project with billing enabled
- Checkov installed 
- Terraform installed
- gcloud CLI installed and authenticated
- SOPS installed and configured with GCP KMS

## Repository Structure

The repository has the following structure:
```
terraform/
├── .github/                     # Contains GitHub Actions workflows
├── apis/                        # Contains GCP module to enable required APIs
├── flux/                        # Contains Flux module to bootstrap Finure Kubernetes repo
├── gcp/                         # Contains variables for various modules, encrypted using SOPS and GCP KMS
├── gcs/                         # Contains module to create GCS buckets
├── gke/                         # Contains module to create private GKE cluster and related resources
├── iam/                         # Contains module to create service accounts and IAM roles/bindings through abstraction
├── iap/                         # Contains module to create a VM to be used as a bastion host to access the cluster via IAP
├── kms/                         # Contains module to create KMS keys and keyrings
├── network/                     # Contains module to create a private VPC with subnets, PGA, and Cloud NAT
├── Makefile/                    # Contains Makefile to simplify bootstrapping and managing the infrastructure
└── README.md                    # Project documentation
```

## Infrastructure Components

The Terraform code in this repository sets up the following infrastructure components:
- **APIs:** Enables required GCP APIs for the project
- **Network:** Creates a private VPC with subnets, Private Google Access (PGA), and Cloud NAT for outbound internet access
- **GKE Cluster:** Creates a private GKE cluster with necessary resources and runs a script to start the IAP TCP tunnel, fetch GKE credentials, configure kube context and modify the context to use the bastion host as a proxy
- **Bastion Host:** Creates a VM instance to be used as a bastion host to access the GKE cluster via IAP
- **GCS Buckets:** Creates GCS buckets required by the Finure apps and GKE cluster
- **KMS Keys:** Creates KMS keyrings and keys for encrypting sensitive data
- **IAM:** Creates service accounts with necessary IAM roles and bindings, along with Workload Identity bindings to securely manage access between GCP and the Kubernetes cluster
- **Flux:** Commits Flux components to Finure Kubernetes repo and configures the Finure cluster to sync with the same repo

## Usage

To bootstrap the entire infrastructure, use the following commands:
1. Run `make bootstrap` to bootstrap the entire infrastructure. This command will initialize the each module, create an execution plan, run checkov and apply the changes to create all the resources defined in the modules.
2. Run `make bootstrap-destroy` to destroy the entire infrastructure created by the `make bootstrap` command.

To manage individual modules, use the following commands:
1. Run `make init module=<module_name>` to initialize the Terraform working directory for a specific module
2. Run `make plan module=<module_name>` to create an execution plan for the specific module while validating the Terraform code using Checkov
3. Run `make apply module=<module_name>` to apply the changes required using SOPS to decrypt the variables file
4. Run `make destroy module=<module_name>` to destroy the created module resources

Additionally, you can use the following commands:
- `make fmt` to format the Terraform code
- `make unlock` to unlock the Terraform state if it gets locked
- `make help` to see all available commands

## Github Actions
The repository includes GitHub Actions workflows to automate the following tasks:
- **Terraform Format:** Ensures that the Terraform code is properly formatted
- **Cost Check:** Validates the cost estimation for the proposed infrastructure changes and posts the result as a comment on the PR
- **Checkov:** Validates the Terraform code using Checkov for security and best practices
- **Label PRs:** Automatically labels pull requests based on the changes made

## Additional Information

This repository is intended to be used as part of the Finure project. While the Terraform code can be adapted for other use cases, it is recommended to use it as part of the Finure platform for full functionality and support.