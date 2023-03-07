variable "account_id" {
  type = string
}

variable "admin_role_arns" {
  type    = list(string)
  default = []
}

variable "admin_user_arns" {
  type    = list(string)
  default = []
}

variable "assume_role" {
  type    = string
  default = ""
}

variable "azs" {
  type = list(string)
}

variable "cluster_endpoint" {
  type    = string
  default = null
}

variable "cluster_certificate_authority_data" {
  type    = string
  default = null
}

variable "region" {
  type = string
}

variable "name" {
  type    = string
  default = "terraform-eks-flux-demo"
}
