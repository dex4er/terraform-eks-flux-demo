## Security group cannot be deleted if there are still network interfaces even
## if EC2 instances are terminated. Removing them manually on `terraform
## destroy` allows to destroy security group too.

resource "null_resource" "sg_node_group_cleanup" {
  triggers = {
    region            = var.region
    security_group_id = module.sg_node_group.security_group_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 describe-network-interfaces --region ${self.triggers.region} --filters --query \"NetworkInterfaces[?Status == 'available' && Groups[?GroupId == '${self.triggers.security_group_id}']].NetworkInterfaceId\" --output text | xargs -rn1 aws ec2 delete-network-interface --region ${self.triggers.region} --network-interface-id"
  }
}

locals {
  sg_node_group_id = null_resource.sg_node_group_cleanup.triggers.security_group_id
}
