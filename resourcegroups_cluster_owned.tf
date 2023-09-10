## Resources created by EKS directly don't have our tags but might have
## `kubernetes.io/cluster/NAME=owned` tag.

resource "aws_resourcegroups_group" "cluster-owned" {
  name = "${var.cluster_name}-owned"

  resource_query {
    query = jsonencode({
      "ResourceTypeFilters" : [
        "AWS::AllSupported"
      ],
      "TagFilters" : [
        {
          "Key" : "kubernetes.io/cluster/${var.cluster_name}",
          "Values" : ["owned"]
        }
      ]
    })
  }

  tags = {
    Name   = "${var.cluster_name}-cluster-owned"
    Object = "aws_resourcegroups_group.cluster-owned"
  }
}
