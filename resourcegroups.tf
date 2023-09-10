## We use common tags then Resource Groups console might list all our
## resources.

resource "aws_resourcegroups_group" "project" {
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
    Object = "aws_resourcegroups_group.project"
  }
}
