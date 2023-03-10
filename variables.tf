variable "account_id" {
  type        = string
  description = "AWS Account ID as a string with leading zeros"
}

variable "admin_role_arns" {
  type        = list(string)
  default     = []
  description = "List of IAM roles with full privileges to the cluster"
}

variable "admin_user_arns" {
  type        = list(string)
  default     = []
  description = "List of IAM users with full privileges to the cluster"
}

variable "assume_role" {
  type        = string
  default     = null
  description = "IAM role to assume by Terraform. If null then current user is used as a cluster creator."
}

variable "azs" {
  type        = list(string)
  description = "List of AZs. AZ ids are preferred rather than names."
}

variable "cluster_in_private_subnet" {
  type        = bool
  default     = false
  description = "By default cluster is created in public subnet to lower montly costs of NAT gateway and service endpoints"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "name" {
  type        = string
  default     = "terraform-eks-flux-demo"
  description = "Name of the cluster and prefix of created AWS resources"
}
