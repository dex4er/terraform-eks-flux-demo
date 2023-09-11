variable "account_id" {
  type        = string
  description = "AWS Account ID as a string with leading zeros"
}

variable "admin_role_arn" {
  type        = string
  description = "IAM role with full privileges to the cluster"
}

variable "asdf_dir" {
  type        = string
  description = "Common asdf directory."
  default     = ".asdf"
}

variable "assume_role" {
  type        = string
  description = "IAM role to assume by Terraform. If null then current user is used as a cluster creator."
  default     = null
}

variable "azs" {
  type        = list(string)
  description = "List of AZs. AZ ids are preferred rather than names."
}

variable "cidr" {
  type        = string
  description = "CIDR for VPC. It should be /18 then subnets will be /24 (18+6)."
  default     = "10.99.0.0/18"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster and prefix of created AWS resources"
  default     = "terraform-eks-flux-demo"
}

variable "cluster_in_private_subnet" {
  type        = bool
  description = "By default cluster is created in public subnet to lower montly costs of NAT gateway and service endpoints"
  default     = false
}

variable "flux_git_repository_url" {
  type        = string
  description = "URL of this Git repository"
}

variable "profile" {
  type        = string
  description = "AWS profile"
  default     = null
}

variable "region" {
  type        = string
  description = "AWS region"
}
