## Self managed groups with defined template

locals {
  node_groups = {
    default-1 = {
      create  = true
      default = true

      labels = {
        "node-group/default" = "true"
      }

      taints = {}

      max_pods = 29

      ## Node group only in first AZ
      azs = [local.azs_ids[0]]

      instance_type = "m5.large"

      ebs_optimized = false

      disk_size  = 25
      iops       = null
      throughput = null

      ami_architecture = "x86_64"
      ami_owner        = "amazon"

      ## https://github.com/awslabs/amazon-eks-ami/releases
      ami_name = "amazon-eks-node-1.24-v20230217"

      pre_bootstrap_user_data = <<-EOT
      yum install -y bind-utils htop lsof mc strace tcpdump
      EOT

      bootstrap_extra_args = "--container-runtime containerd"

      kubelet_extra_args = ""

      post_bootstrap_user_data = <<-EOT
      EOT

      min_size     = 1
      max_size     = 4
      desired_size = 1

      capacity_type = "SPOT"

      instance_refresh_percentage = 90
    }
  }
}

module "eks_node_group" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/self-managed-node-group
  source  = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
  version = "~> 19.10"

  for_each = { for k, v in local.node_groups : k => v if v.create }

  use_name_prefix = false
  name            = "${module.eks.cluster_name}-node-group-${each.key}"

  cluster_name = module.eks.cluster_name

  cluster_endpoint    = module.eks.cluster_endpoint
  cluster_auth_base64 = module.eks.cluster_certificate_authority_data

  cluster_version = module.eks.cluster_version

  create_iam_instance_profile = false
  iam_instance_profile_arn    = aws_iam_instance_profile.this[each.key].arn

  iam_role_attach_cni_policy = true

  subnet_ids = [for i, v in each.value.azs : local.subnets_ids_by_azs[v]]

  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [local.sg_node_group_id]

  instance_type = each.value.instance_type
  ebs_optimized = each.value.ebs_optimized

  ami_id                 = data.aws_ami.eks_node_group[each.key].image_id
  create_launch_template = true

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      instance_warmup        = 120
      min_healthy_percentage = each.value.instance_refresh_percentage
      skip_matching          = true
    }
  }

  launch_template_use_name_prefix = false
  launch_template_name            = "${module.eks.cluster_name}-node-group-${each.key}"
  launch_template_tags = {
    Name = "${module.eks.cluster_name}-node-group-${each.key}"
  }

  pre_bootstrap_user_data = each.value.pre_bootstrap_user_data
  bootstrap_extra_args = join(" ", [
    each.value.bootstrap_extra_args,
    "--dns-cluster-ip", cidrhost(local.cluster_service_cidr, 10),
    "--kubelet-extra-args", "\"${join(" ", compact(flatten([
      each.value.kubelet_extra_args,
      "--max-pods=${each.value.max_pods > 0 ? each.value.max_pods : "$(/etc/eks/max-pods-calculator.sh --instance-type-from-imds --cni-version 1.10.0 --show-max-allowed)"}",
      "--node-labels=eks.amazonaws.com/capacityType=${each.value.capacity_type},eks.amazonaws.com/nodegroup=${each.key},${join(",", [for k, v in each.value.labels : "${k}=${v}"])}",
      length(each.value.taints) > 0 ? "--register-with-taints=${join(",", [for k, v in each.value.taints : "${k}=${v}"])}" : "",
    ])))}\"",
  ])
  post_bootstrap_user_data = each.value.post_bootstrap_user_data

  min_size     = each.value.min_size
  max_size     = each.value.max_size
  desired_size = each.value.desired_size

  use_mixed_instances_policy = each.value.capacity_type == "SPOT"
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized-prioritized"
    }
  }

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

  enabled_metrics = [
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity",
  ]

  service_linked_role_arn = local.service_linked_role_arn

  autoscaling_group_tags = merge(
    {
      "k8s.io/cluster-autoscaler/enabled" : "true",
      "k8s.io/cluster-autoscaler/${module.eks.cluster_name}" : "owned",
      "k8s.io/cluster-autoscaler/node-template/label/eks.amazonaws.com/capacityType" = each.value.capacity_type
    },
    { for k, v in each.value.labels :
      "k8s.io/cluster-autoscaler/node-template/label/${k}" => v
    },
    { for k, v in each.value.taints :
      "k8s.io/cluster-autoscaler/node-template/taint/${k}" => v
    },
    {
      "k8s.io/cluster-autoscaler/node-template/resources/cpu"    = try(try(each.value.resources.cpu, local.instance_resources[each.value.instance_type].cpu), "")
      "k8s.io/cluster-autoscaler/node-template/resources/memory" = try(try(each.value.resources.memory, local.instance_resources[each.value.instance_type].memory), "")
      "k8s.io/cluster-autoscaler/node-template/resources/pods"   = try(try(each.value.max_pods, local.instance_resources[each.value.instance_type].pods), "")
    },
  )

  tags = {
    Name      = "${var.name}-node-group-${each.key}"
    Cluster   = var.name
    NodeGroup = "${var.name}-node-group-${each.key}"
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
    default_node_group = module.eks_node_group[local.default_node_group].autoscaling_group_name
  }

  depends_on = [
    null_resource.aws_auth,
  ]
}
