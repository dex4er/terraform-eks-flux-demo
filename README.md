# terraform-eks-flux-demo

Demo of the application deployed in EKS cluster using Flux with OCI
repository instead of Git repository.

EKS cluster has features:

- has nodes in a public or private network with ELB endpoints in public network
  and master nodes in intra network
- encrypted at rest
- has customized nodes in self-managed node group
- enabled AWS load balancer controller
- enabled metrics-server
- exposes podinfo application

The demo uses <https://github.com/terraform-aws-modules> modules. All modules and
resources and in main directory to make modifications easier so this project can
be easily used as a base for other demos and experiments.

## Architecture

```mermaid
flowchart LR

user{User}
user:::person

subgraph publicSubnet[Public Subnetwork]
  subgraph eksNode[EKS Node]
    subgraph hello[Hello World application]
    end
    kuhellott:::internalContainer
  end

  subgraph alb[ALB]
  end
  alb:::internalComponent
end
publicSubnet:::externalSystem

subgraph intraSubnet[Intra Subnetwork]
  subgraph eksControl[EKS Control Plane]
  end
  eksControl:::internalContainer
end
intraSubnet:::externalSystem

user--HTTP-->alb

alb--HTTP-->hello

eksNode<--API-->eksControl

classDef person fill:#08427b
classDef internalContainer fill:#1168bd
classDef internalComponent fill:#4b9bea
classDef externalSystem fill:#999999
```

## Prerequisities

### AWS account

If you don't use SSO then I recommend creating an IAM user with
`AdministratorAccess` permissions.

1. Go to <https://us-east-1.console.aws.amazon.com/iamv2/home?region=eu-central-1#/users>
2. `[Add users]`
3. User name: admin
4. Attach policies directly: AdministratorAccess
5. `[Next]`
6. `[Create user]`
7. Write down an ARN of the user: it might be like `arn:aws:iam::123456789012:user/admin`

Create an access key for this user:

1. Go to <https://us-east-1.console.aws.amazon.com/iamv2/home#/users/details/admin?section=security_credentials>
2. `[Create access key]`
3. `(*) Application running outside AWS`
4. `[Next]`
5. `[Create access key]`
6. `[Download .csv file]` or copy-paste separate fields somewhere securely or
   use it with `granted credentials add` command as later is described.

The Terraform should be able to assume the dedicated role.

1. Go to <https://us-east-1.console.aws.amazon.com/iamv2/home?region=eu-central-1#/roles>
2. `[Create role]`
3. Custom trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:root",
          "arn:aws:iam::123456789012:user/admin"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

1. `[Next]`
2. Add permissions: AdministratorAccess
3. `[Next]`
4. Role name: Admin
5. `[Create role]`
6. Write down an ARN of the role: it might be like `arn:aws:iam::123456789012:role/Admin`

### asdf

All required tools can be installed with <https://asdf-vm.com/>:

```sh
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2
. "$HOME/.asdf/asdf.sh"
while read plugin version; do asdf plugin add $plugin || test $? = 2; done < .tool-versions
asdf install
```

Additionally, I recommend using https://granted.dev/ for switching between AWS accounts:

```sh
asdf plugin add granted
asdf install granted latest
asdf global granted latest
```

then `~/.aws/config` might be:

```ini
[profile default]
output             = json
region             = eu-central-1
credential_process = granted credential-process --profile=default
```

and credentials can be added with the command:

```sh
granted credentials add
```

```console
? Profile Name: default
? Access Key ID: XXXXXXXXX
? Secret Sccess Key: *****************
Saved default to secure storage
```

You can switch to your profile:

```sh
assume default
```

## Usage

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
account_id              = "123456789012"
assume_role             = "arn:aws:iam::123456789012:role/Admin"
azs                     = ["euc1-az1", "euc1-az2", "euc1-az3"]
cluster_name            = "eks-flux-demo"
flux_git_repository_url = "https://github.com/dex4er/terraform-eks-flux-demo.git"
profile                 = "default"
region                  = "eu-central-1"
```

- Run Terraform:

```sh
terraform init
terraform apply
```

- Connect to the cluster:

```sh
terraform output
# check for cluster_update_kubeconfig_command and run the command, ie.:
aws eks update-kubeconfig --name eks-flux-demo --region eu-central-1 --role arn:aws:iam::123456789012:role/Admin
```

- Connect to ingress:

```sh
kubectl get ingress -n hello-world
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

It should happen during destroying of `shell_script.flux_bootstrap`.

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
cluster is not available or about to replace or destroy. `shell_script` is
used instead as an experiment if it is possible to communicate with
Kubernetes without a provider. It might be changed to the shared directory
with `asdf_dir` variable when it is possible to run pre-apply commands (ie.
Gitlab CI, GitHub Actions, Spacelift, etc.) or Terraform is run locally.

## Terraform Cloud

The project is ready to use with the Terraform Cloud. In this case, after the
state will is no longer local and might be used by more developers.

In this case the workspace should have Execution Mode: Remote. All variables from
`terraform.tfvars` file should be added as "Workspace variables" (note: arrays
should be added as HCL).

Variables for AWS API (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) might be
added as "Variable sets".

## Spacelift

The project is ready to use with Spacelift.

Spacelift can use custom container images, so it is suggested to use such a
container with preinstalled [asdf](https://asdf-vm.com/), ie.
[dex4er/debian-asdf](https://hub.docker.com/r/dex4er/debian-asdf).

In this case use customized workflow and add the commands to pre-Applying and pre-Performing scripts:

```sh
cp .tool-versions /root
while read plugin version; do asdf plugin add $plugin || test $? = 2; done < .tool-versions
asdf install
```

Beside `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (both not important if you
use cloud integration) and `AWS_REGION` environment variables, you should create
`/mnt/workspace/source/terraform.tfvars` mounted file with the content of your
`terraform.tfvars` file. In this file add `asdf_dir = "/root/.asdf"` Terraform
variable.

### Updates

Currently, the latest tag is used in the podinfo Deployment. It is suggested to
add ImageUpdateAutomation and ImagePolicy for automated upgrades when
OCIRegistry will be replaced with GitRegistry.

Because Flux uses the OCI registry rather than the Git registry, there are no
automated deployments after changes in the Git repository. In that case either
switch to GitRepository as a source for Flux or call `terraform apply` after
each change in a `/flux` directory.

## TODO

- The cluster should be moved to private subnetwork (raises the monthly cost by
  ~$400 for a NAT gateway and service endpoints).
- Nodes should use Bottlerocket OS rather than standard Amazon Linux.
- It should be avoided docker.io as a OCI registry. `k8s-image-swapper` service
  might help to automatize the cloning of images to private ECR.
- Additional controllers are needed if PersistentVolumes will be used then
  another StorageClass might be used in place of the default.
- AWS Node Termination Handler should be installed for safer handling of spot
  instances.
- The cluster misses Prometheus. External AWS Prometheus instance might be used
  for longer-term storage.
- It might be considered using Istio or Cilium for better observability.
- It is a good idea to use Velero backup if some persistent volumes will exist.
