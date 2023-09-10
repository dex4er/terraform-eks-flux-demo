## ECR repository dedicated to Flux for this cluster

module "ecr_flux_system" {
  ## https://github.com/terraform-aws-modules/terraform-aws-ecr
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6"

  repository_name = "${var.name}-flux-system"

  repository_image_tag_mutability = "MUTABLE"

  create_lifecycle_policy       = false
  repository_image_scan_on_push = false

  repository_force_delete = true

  tags = {
    Name   = "${var.name}-flux-system"
    Object = "module.ecr_flux_system"
  }
}

locals {
  flux_system_repository_url = module.ecr_flux_system.repository_url
}
