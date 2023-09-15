## EKS managed groups with defined template

locals {
  node_groups = {
    default-1-25-v20230825 = {
      create  = true
      default = true

      labels = {
        "node-group/default" = "true"
      }

      taints = {}

      max_pods = 29

      ## Node group only in first AZ
      azs = [local.azs_ids[0]]

      instance_types = [
        "m5.large",
        "m5n.large",
      ]

      ebs_optimized = false

      disk_size  = 25
      iops       = null
      throughput = null

      ami_architecture = "x86_64"
      ami_owner        = "amazon"

      ## https://github.com/awslabs/amazon-eks-ami/releases
      # ami_name = "amazon-eks-node-1.25-v20230825"

      pre_bootstrap_user_data = <<-EOT
      yum install -y bind-utils htop lsof mc strace tcpdump
      EOT

      post_bootstrap_user_data = <<-EOT
      EOT

      min_size     = 1
      max_size     = 4
      desired_size = 3

      capacity_type = "SPOT"
    }
  }
}

module "eks_node_group" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.10"

  for_each = { for k, v in local.node_groups : k => v if v.create }

  use_name_prefix = false
  name            = "${module.eks.cluster_name}-node-group-${each.key}"

  cluster_name = module.eks.cluster_name

  cluster_endpoint    = module.eks.cluster_endpoint
  cluster_auth_base64 = module.eks.cluster_certificate_authority_data

  cluster_version = module.eks.cluster_version

  create_iam_role            = false
  iam_role_arn               = module.iam_role_node_group.iam_role_arn
  iam_role_attach_cni_policy = false

  subnet_ids = [for i, v in each.value.azs : local.subnets_ids_by_azs[v]]

  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [local.sg_node_group_id]

  instance_types = each.value.instance_types
  ebs_optimized  = each.value.ebs_optimized

  ami_id                 = lookup(each.value, "ami_name", null) != null ? data.aws_ami.eks_node_group[each.key].image_id : null
  create_launch_template = true

  launch_template_use_name_prefix = false
  launch_template_name            = "${module.eks.cluster_name}-node-group-${each.key}"
  launch_template_tags = {
    Name = "${module.eks.cluster_name}-node-group-${each.key}"
  }

  pre_bootstrap_user_data  = each.value.pre_bootstrap_user_data
  post_bootstrap_user_data = each.value.post_bootstrap_user_data

  min_size     = each.value.min_size
  max_size     = each.value.max_size
  desired_size = each.value.desired_size

  block_device_mappings = {
    xvda = {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = each.value.disk_size
        volume_type           = "gp3"
        iops                  = each.value.iops
        throughput            = each.value.throughput
        encrypted             = true
        kms_key_id            = "arn:aws:kms:${var.region}:${var.account_id}:alias/aws/ebs"
        delete_on_termination = true
      }
    }
  }

  network_interfaces = [
    {
      associate_public_ip_address = var.cluster_in_private_subnet ? false : true
      delete_on_termination       = true
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name      = "${var.cluster_name}-node-group-${each.key}"
    Cluster   = var.cluster_name
    NodeGroup = "${var.cluster_name}-node-group-${each.key}"
    Object    = "module.eks_node_group"
  }
}

locals {
  default_node_groups = { for k, v in local.node_groups : k => v if v.create && v.default }
  default_node_group  = element(sort(keys(local.default_node_groups)), length(local.default_node_groups) - 1)
}

resource "time_sleep" "eks_default_node_group_delay" {
  create_duration = "2m"

  triggers = {
    ## It makes a dependency on the default node group but we need more static string
    ## ID before colon is the same as cluster name.
    default_node_group = try(module.eks_node_group[local.default_node_group].node_group_id, module.eks.cluster_name)
  }
}

output "eks_node_group" {
  description = "Outputs from EKS managed node groups module"
  value       = module.eks_node_group
}
