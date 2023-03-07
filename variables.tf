variable "account_id" {
  type = string
}

variable "assume_role" {
  type    = string
  default = ""
}

variable "azs" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "name" {
  type    = string
  default = "terraform-eks-flux-demo"
}

variable "instance_type" {
  type    = string
  default = "m5.large"
}
