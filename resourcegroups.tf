## We use common tags then Resource Groups console might list all our
## resources.

resource "aws_resourcegroups_group" "project" {
  name = var.name

  resource_query {
    query = jsonencode({
      "ResourceTypeFilters" : [
        "AWS::AllSupported"
      ],
      "TagFilters" : [
        {
          "Key" : "Project",
          "Values" : [var.name]
        }
      ]
    })
  }

  tags = {
    Name   = var.name
    Object = "aws_resourcegroups_group.project"
  }
}
