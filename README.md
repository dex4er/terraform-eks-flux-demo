# terraform-eks-flux-demo

Simple demo of the application deployed in EKS cluster using Flux with OCI
repository instead of Git repository.

EKS cluster is in a private network with ELB endpoints in public network and
master nodes in intra network.

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
account_id  = "123456789012"
assume_role = "arn:aws:iam::123456789012:role/Admin"
azs         = ["use2-az1", "use2-az2", "use2-az3"]
region      = "us-east-2"
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

```sh
flux suspend ks all
flux suspend source oci --all
kubectl get ks -n flux-system --no-headers | grep -v -P '^(all|flux-system)' | while read name _rest; do echo kubectl delete ks $name -n flux-system --ignore-not-found; done | bash -ex
sleep 300
flux uninstall --keep-namespace=true --silent
terraform destroy
```

## Note

EKS cluster should be created from the session run in a dedicated role. Such a
user or role is a super user for the cluster and this parameter is invisible in
a panel or API and can't be changed later.

The state for Terraform should be local because `local_file` resources are used
for extra files generated: OCIRepository and environment variables for Flux.

`local-exec` runs `aws`, `kubectl` and `flux` commands.
