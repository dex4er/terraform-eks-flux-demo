## Some resources (like IAM) are only in us-east-1

resource "aws_resourcegroups_group" "project_global" {
  count = var.region != "us-east-1" ? 1 : 0

  provider = aws.global

  name = var.cluster_name

  resource_query {
    query = jsonencode({
      "ResourceTypeFilters" : [
        "AWS::AllSupported"
      ],
      "TagFilters" : [
        {
          "Key" : "Project",
          "Values" : [var.cluster_name]
        }
      ]
    })
  }

  tags = {
    Name   = var.cluster_name
    Object = "aws_resourcegroups_group.project_global"
  }
}
