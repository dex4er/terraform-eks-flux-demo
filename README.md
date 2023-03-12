# terraform-eks-flux-demo

Demo of the application deployed in EKS cluster using Flux with OCI
repository instead of Git repository.

EKS cluster has features:

- has nodes in a public or private network with ELB endpoints in public network
  and master nodes in intra network
- encrypted at rest
- has customized nodes in self-managed node group
- enabled autoscaler and AWS load balancer controller
- exposes podinfo application

The demo uses https://github.com/terraform-aws-modules> modules. All modules and
resources and in main directory to make modifications easier so this project can
be easily used as a base for other demos and experiments.

## Usage

- Configure AWS:

```sh
aws configure sso
```

or use [Granted](https://granted.dev/).

- Check current context:

```sh
aws sts get-caller-identity
```

- Check what AZs are available:

```sh
aws ec2 describe-availability-zones --region $AWS_REGION --query 'AvailabilityZones[*].ZoneId'
```

- Create `terraform.tfvars` file, ie.:

```tf
account_id                = "123456789012"
assume_role               = "arn:aws:iam::123456789012:role/Admin"
azs                       = ["use2-az1", "use2-az2", "use2-az3"]
region                    = "us-east-2"
```

- Run Terraform:

```sh
terraform init
terraform apply
```

- Connect to ingress:

```sh
kubectl get ingress -n podinfo
curl http://$ADDRESS
```

## Shutdown

Workloads in the cluster must be removed in the correct order to prevent leaving
orphaned resources:

1. Stopping Flux updates.
2. Removing all kustomizations except AWS resource controllers and Flux "all"
   kustomization.
3. Removing AWS resource controllers.
4. Uninstalling Flux.

It should happen during destroying of `null_resource`.flux_kustomization_all`.

## Note

EKS cluster should be created from the session run in a dedicated role. Such a
user or role is a super user for the cluster and this parameter is invisible in
a panel or API and can't be changed later. It is better to use `assume_role`
variable to switch Terraform to such a role rather than to use AWS user or root
account. `caller_identity` output is presented for verification if the correct
role is assumed.

EKS cluster nodes will be created with public IPs to save the cost of NAT
servers and service endpoints. It might be switched to private IPs with
`cluster_in_private_subnet` variable.

The demo avoids Kubernetes Provider as it leads to many problems when the
cluster is not available or about to replace or destroy. `local-exec` is used
instead as an experiment if it is possible to communicate with Kubernetes
without a provider. Unfortunately, it is problematic to use additional tools in
Terraform Cloud runs so a current solution is suboptimal: it installs each copy
of an external tool separately for each `null_resource`. It might be changed to
the shared directory with `asdf_dir` variable when it is possible to run
pre-apply commands (ie. Gitlab CI, GitHub Actions, Spacelift, etc.) or Terraform
is run locally.
