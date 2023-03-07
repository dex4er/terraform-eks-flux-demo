## It is potentially dangerous to clean up security groups and network
## interfaces but they're leftovers from working EKS cluster and they'll hold
## `terraform destroy` for long time otherway.

resource "null_resource" "vpc_cleanup" {
  triggers = {
    region = var.region
    vpc_id = module.vpc.vpc_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 describe-security-groups --region ${self.triggers.region} --query \"SecurityGroups[?GroupName != 'default' && VpcId == '${self.triggers.vpc_id}'].GroupId\" --output text | xargs -rn1 aws ec2 delete-security-group --region ${self.triggers.region} --group-id"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 describe-network-interfaces --region ${self.triggers.region} --filters --query \"NetworkInterfaces[?Status == 'available' && VpcId == '${self.triggers.vpc_id}'].NetworkInterfaceId\" --output text | xargs -rn1 aws ec2 delete-network-interface --region ${self.triggers.region} --network-interface-id"
  }
}

output "vpc_id" {
  value = null_resource.vpc_cleanup.triggers.vpc_id
}
