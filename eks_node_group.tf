## EKS managed groups with defined template

locals {
  node_groups = {
    initial = {
      create  = true
      default = true

      labels = {
        "nodegroup"         = "initial"
        "nodegroup/initial" = "true"
      }

      taints = {
        CriticalAddonsOnly = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      # max_pods = 29

      # ## Node group only in first AZ
      # azs = [local.azs_ids[0]]
      azs = local.azs_ids

      instance_types = [
        ## 2vCPU, 2GiB RAM
        "t3.small",
        "t3a.small",
        ## 2vCPU, 4GiB RAM
        "t3.medium",
        "t3a.medium",
      ]

      capacity_type = "SPOT"

      ebs_optimized = false

      # disk_size = 50

      block_device_mappings = {
        boot = {
          ## nvme0n1
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 4
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = "arn:aws:kms:${var.region}:${var.account_id}:alias/aws/ebs"
            delete_on_termination = true
          }
        }
        local = {
          ## nvme2n1
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = "arn:aws:kms:${var.region}:${var.account_id}:alias/aws/ebs"
            delete_on_termination = true
          }
        }
        containerd = {
          ## nvme1n1
          device_name = "/dev/xvdc"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = "arn:aws:kms:${var.region}:${var.account_id}:alias/aws/ebs"
            delete_on_termination = true
          }
        }
      }

      platform = "bottlerocket"

      # ami_type = "AL2"

      ami_architecture = "x86_64"
      ami_owner        = "amazon"

      ## https://github.com/awslabs/amazon-eks-ami/releases
      # ami_name = "amazon-eks-node-1.25-v20230825"

      ## https://ubuntu.com/server/docs/cloud-images/amazon-ec2
      ## $ aws --region eu-central-1 ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu-eks/k8s_1.25/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" --query 'reverse(sort_by(Images, &Name))[0].Name' --output text | cat
      # ami_name = "ubuntu-eks/k8s_1.25/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20231007"

      ## $ aws --region eu-central-1 ec2 describe-images --owners amazon --filters "Name=name,Values=bottlerocket-aws-k8s-1.25-x86_64-*" --query 'reverse(sort_by(Images, &Name))[0].Name' --output text | cat
      ami_name = "bottlerocket-aws-k8s-1.25-x86_64-v1.15.1-264e294c"

      bootstrap_extra_args = <<-EOT
        registry-qps = 0
        [settings.host-containers.admin]
        enabled = true
        [settings.bootstrap-containers.bootstrap]
        source = "public.ecr.aws/stefansundin/bottlerocket-bootstrap-exec-user-data:latest"
        mode = "always"
        essential = false
        user-data = "${filebase64("eks_node_group_bootstrap_initial.sh")}"
      EOT

      # pre_bootstrap_user_data = <<-EOT
      # EOT

      # post_bootstrap_user_data = <<-EOT
      # EOT

      min_size     = 3
      max_size     = 4
      desired_size = 3
    }
  }
}

module "eks_node_group" {
  ## https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.10"

  for_each = { for k, v in local.node_groups : k => v if v.create }

  use_name_prefix = false
  name            = "${module.eks.cluster_name}-${each.key}"

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

  platform                   = lookup(each.value, "platform", null)
  ami_type                   = lookup(each.value, "ami_type", null)
  ami_id                     = lookup(each.value, "ami_name", null) != null ? data.aws_ami.eks_node_group[each.key].image_id : null
  create_launch_template     = lookup(each.value, "ami_type", null) == null ? true : false
  use_custom_launch_template = lookup(each.value, "ami_type", null) == null ? true : false

  launch_template_use_name_prefix = false
  launch_template_name            = "${module.eks.cluster_name}-${each.key}"
  launch_template_tags = {
    Name = "${module.eks.cluster_name}-${each.key}"
  }

  enable_bootstrap_user_data = lookup(each.value, "ami_type", null) == null ? true : false
  bootstrap_extra_args = lookup(each.value, "platform", null) == "bottlerocket" ? join("\n", compact(
    [
      "\"cluster-dns-ip\" = \"${cidrhost(local.cluster_service_cidr, 10)}\"",
      lookup(each.value, "bootstrap_extra_args", "")
    ]
    )) : join(" ", compact(
    [
      lookup(each.value, "bootstrap_extra_args", ""),
      "--dns-cluster-ip=${cidrhost(local.cluster_service_cidr, 10)}",
    ]
  ))
  pre_bootstrap_user_data  = lookup(each.value, "pre_bootstrap_user_data", "")
  post_bootstrap_user_data = lookup(each.value, "post_bootstrap_user_data", "")

  min_size     = each.value.min_size
  max_size     = each.value.max_size
  desired_size = each.value.desired_size

  labels = each.value.labels
  taints = each.value.taints

  disk_size             = lookup(each.value, "ami_type", null) != null ? each.value.disk_size : null
  block_device_mappings = lookup(each.value, "ami_type", null) == null ? each.value.block_device_mappings : null

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
    Name      = "${var.cluster_name}-${each.key}"
    AmiName   = lookup(each.value, "ami_name", null)
    Cluster   = var.cluster_name
    NodeGroup = "${var.cluster_name}-${each.key}"
    Object    = "module.eks_node_group"
  }
}

resource "time_sleep" "eks_default_node_group_delay" {
  create_duration = "5m"

  triggers = {
    ## Adds additional delay after cluster is created so addons won't be
    ## installed before nodegroups will be ready.
    cluster_name = module.eks.cluster_name
  }
}

output "eks_node_group" {
  description = "Outputs from EKS managed node groups module"
  value       = module.eks_node_group
}
