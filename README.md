# Terraform Google GKE Cluster

A Terraform module to create a best-practice Google Kubernetes Engine (GKE) cluster.

This module is available on [Terraform registry](https://registry.terraform.io/modules/jetstack/gke-cluster/google/).

The module is designed to be used by Jetstack customers to make it easier for them to create clusters that are secure and follow Jetstack recommendations.
It gives them flexibility with certain properties so the cluster can be customised to their needs, but gives fixed values for properties that could lead to issues or insecurity.

## Deprecation

:warning:
**The `0.3` release of this module is planned to be the final release.**
:warning:

After this the module will be deprecated in favour of [Google's GKE module](https://github.com/terraform-google-modules/terraform-google-kubernetes-engine).
Jetstack will be producing an example project using Google's module as well as migration guidance.

## Requirements

The module requires an existing Google Cloud project, with VPC network and subnetwork for the cluster to use.
The subnetwork must be in the same region as the cluster and have pod and service ranges specified.

## Customisable Properties

The module allows the cluster to be extensively customised using input variables.
These can be found with documentation in [`variables.tf`](variables.tf).

The customisable properties include:
- Release channel or minimum master version
- Private nodes
- Master private endpoint
- Master authorised network CIDR blocks
- Master CIDR block
- Node service account container registry access
- Google security group for RBAC
- Workload identity namespace
- Enable Stackdriver logging and monitoring
- Enable Google Cloud HTTP load balancing
- Enable pod security policy controller
- Daily maintenance window start time
- Node pools
  - Name
  - Inital node count
  - Minimum and maximum number of nodes for autoscaling
  - Enable automatic repair and upgrade
  - Machine type
  - Disk size and type
  - Use preemptible nodes
  - Kubernetes version

## Fixed Arguments

Some of the properties of the cluster are fixed based on Jetstack's recommended best-practice settings:
- Enabling network policy for nodes and master using Calico.
- Disabling basic authentication and client certificate issuing.
- Disabling Kubernetes dashboard (Google Cloud Console should be used instead).
- Use of VPC native networking (using a specified network and subnetwork).
- Removing the default node pool and creating one or more new pools with Terraform for easier management.
- Setting the OAuth scope of nodes to `cloud-platform` to manage permissions with IAM.
- Disabling node legacy endpoints.
- Creating an IAM service account for nodes with the minimum required roles:
  - Logging log writer
  - Monitoring metric writer
  - Monitoring viewer

## Usage

The module itself is located in the root of this repo, and is designed to be used as part of a larger Terraform project.
It can be used directly from the Terraform Registry like so:

```
module "gke-cluster" {
  source  = "jetstack/gke-cluster/google"
  version = "0.3.0"

  # insert the 9 required variables here
}
```

## Example

There is an [example project](https://github.com/jetstack/terraform-google-gke-cluster/tree/master/example) in the `example/` directory which can be used to test and demonstrate the module. It could also be used as the basis for your own Terraform project.

## Limitations

If private nodes are used then **nodes will not have direct access to the internet**.
This means they cannot pull images hosted outside of the container registry in the same project as the cluster.
The example project features a [Cloud NAT](https://cloud.google.com/nat/docs/overview) to give the nodes to access the internet.

## License

This project is licensed under the [Apache 2.0 License](https://choosealicense.com/licenses/apache-2.0/).
For full details see the `LICENSE` file.
