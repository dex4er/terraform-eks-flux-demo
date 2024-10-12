## EKS managed groups with defined template

locals {
  eks_managed_node_group_defaults = {
    create_iam_role            = false
    iam_role_arn               = module.iam_role_node_group.iam_role_arn
    iam_role_attach_cni_policy = false

    attach_cluster_primary_security_group = true
  }

  ## https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group
  eks_node_groups = {
    default = {
      create = true

      use_name_prefix                 = true
      name                            = "${var.cluster_name}-default"
      launch_template_use_name_prefix = true
      launch_template_name            = "${var.cluster_name}-default"

      # ## Node group only in first AZ
      # azs = [local.azs_ids[0]]
      azs = local.azs_ids

      instance_types = [
        ## 2vcpu, 4GiB
        "t4g.medium",
        "c6g.large",
        "c6gd.large",
        "c6gn.large",
        "c7g.large",
        "c7gd.large",
        "c8g.large",
      ]

      capacity_type = "SPOT"

      ebs_optimized = false

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
          ## nvme1n1
          device_name = "/dev/xvdb"
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

      ami_type = "BOTTLEROCKET_ARM_64"

      # ami_architecture = "x86_64"
      # ami_owner        = "amazon"

      ## https://github.com/awslabs/amazon-eks-ami/releases
      # ami_name = "amazon-eks-arm64-node-1.31-v20240928"

      ## https://ubuntu.com/server/docs/cloud-images/amazon-ec2
      ## $ aws --region eu-central-1 ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu-eks/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*" --query 'reverse(sort_by(Images, &Name))[0].Name' --output text | cat
      # ami_name = "ubuntu-eks/k8s_1.31/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-20240930"

      ## $ aws --region eu-central-1 ec2 describe-images --owners amazon --filters "Name=name,Values=bottlerocket-aws-k8s-1.31-x86_64-*" --query 'reverse(sort_by(Images, &Name))[0].Name' --output text | cat
      # ami_name = "bottlerocket-aws-k8s-1.31-x86_64-v1.15.1-314e294c"

      bootstrap_extra_args = <<-EOT
        max-pods = 18
        registry-qps = 0
        [settings.host-containers.admin]
        enabled = true
      EOT

      # pre_bootstrap_user_data = <<-EOT
      # EOT

      # post_bootstrap_user_data = <<-EOT
      # EOT

      min_size     = 3
      max_size     = 4
      desired_size = 3

      labels = {}
      taints = []

      tags = {
        Nodegroup = "default"
      }
    }
  }
}
