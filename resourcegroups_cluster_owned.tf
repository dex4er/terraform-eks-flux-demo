## Resources created by EKS directly don't have our tags but might have
## `kubernetes.io/cluster/NAME=owned` tag.

resource "aws_resourcegroups_group" "cluster-owned" {
  name = "${var.name}-owned"

  resource_query {
    query = jsonencode({
      "ResourceTypeFilters" : [
        "AWS::AllSupported"
      ],
      "TagFilters" : [
        {
          "Key" : "kubernetes.io/cluster/${var.name}",
          "Values" : ["owned"]
        }
      ]
    })
  }

  tags = {
    Name   = "${var.name}-cluster-owned"
    Object = "aws_resourcegroups_group.cluster-owned"
  }
}
