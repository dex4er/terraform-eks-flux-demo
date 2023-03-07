## Parameters of instance types used by Autoscaler

locals {
  instance_resources = {
    "m5.large" = {
      cpu    = "2"
      memory = "7932428Ki"
      pods   = "29"
    },
  }
}
