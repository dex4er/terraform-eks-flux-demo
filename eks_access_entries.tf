locals {
  access_entries = {
    admin = {
      principal_arn = coalesce(var.admin_role_arn, local.caller_role_arn)
      policy_associations = {
        cluster = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
