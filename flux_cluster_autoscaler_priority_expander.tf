## List of allowed node groups with priorities. Higher priority is more
## important.
##
## If new node group is created with the same prefix but different number
## then autoscaler prefers newer node group. It allows to do safe upgrade of
## the nodes in the cluster.

resource "local_file" "flux_cluster_autoscaler_priority_expander" {
  content = yamlencode({
    apiVersion : "v1"
    kind : "ConfigMap"
    metadata : {
      name : "cluster-autoscaler-priority-expander"
      namespace : "kube-system"

      labels : {
        "app.kubernetes.io/instance" : "cluster-autoscaler"
        "app.kubernetes.io/name" : "aws-cluster-autoscaler"
      }
    }

    ## https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/expander/priority/readme.md
    data : {
      priorities : replace(yamlencode(transpose(
        {
          for kg, vg in local.node_groups : ("^${var.name}-node-group-${kg}$") => [try(regex("-(\\d+)$", kg), ["0"])[0]] if vg.create
        }
      )), "/(?m)^\"(\\d+)\":/", "$1:")
    }
  })

  filename             = "flux/cluster-autoscaler/configmap-cluster-autoscaler-priority-expander.yaml"
  directory_permission = "0755"
  file_permission      = "0644"
}
