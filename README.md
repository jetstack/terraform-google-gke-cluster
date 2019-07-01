# Terraform Google GKE Cluster

A Terraform module to create a best-practise Google Kubernetes Engine (GKE) cluster.

This module is availble on [Terraform registry](https://registry.terraform.io/modules/jetstack/gke-cluster/google/).

The module is designed to be used by Jetstack customers to make it easier for them to create clusters that are secure and follow Jetstack recommendations.
It gives them flexibility with certain properties so the cluster can be customised to their needs, but gives fixed values for properties that could lead to issues or insecurity.

## Customisable Properties

The module allows for properties of the cluster to be customised by setting Terraform resource arguments with input variables.
These are:

- GCP project ID
- Cluster name
- GCP location
  - Specify a zone for a zonal cluster (e.g. europe-west1-b)
  - Specify a region for a regional cluster (e.g. europe-west1)
- Maintenance window start time
- Node pools
  - Name
  - Initial size
  - Machine type
  - Disk type and size
  - Autoscaling min and max
  - Enable auto repair and upgrade
- VPC network and subnetwork names
- Cluster and service range name
- Enable access to private GCR images (defaults to false)
- Disable HTTP load balancing (defaults to false, i.e. HTTP load balancing is enabled)
- Master CIDR block (defaults to 172.16.0.0/28)
- Master authorized CIDR blocks (defaults to 0.0.0.0/0 i.e. everywhere)

Note that the VPC network and subnetwork specified must already exist.
The subnetwork must also have the cluster and service ranges specified.

## Fixed Arguments

Many of the properties of the cluster are set as Terraform resource arguments with fixed values.
These values are based on Jetstack's recommended best-practice settings.
These are:

- Setting master version to latest
- Enabling private nodes so they aren't reachable externally
- Disabling private master so it is reachable externally (this can be restricted with master authorized CIDR blocks)
- Enabling network policy for nodes using Calico
- Enabling network policy master addon
- Disabling basic authentication and client certificate issuing
- Disabling Kubernetes dashboard (Google Cloud Console should be used instead)
- Use of VPC native networking (using a specified network and subnetwork)
- Enabling IP aliases
- Removing the default node pool and creating one or more new pools with Terraform for easier management
- Setting the OAuth scope of nodes to `cloud-platform` to manage permissions with IAM
- Disabling node legacy endpoints
- Creating an IAM service account for nodes with the minimum required roles
  - Logging log writer
  - Monitoring metric writer
  - Monitoring viewer

## Usage

The module itself is located in the root of this repo, and is designed to be used as part of a larger Terraform project.
It can be used directly from the Terraform Registry like so:

```
module "gke-cluster" {
  source  = "jetstack/gke-cluster/google"
  version = "0.1.0"

  # insert the 9 required variables here
}
```

## Example

There is an [example project](https://github.com/jetstack/terraform-google-gke-cluster/tree/master/example) in the `example/` directory which can be used to test and demonstrate the module. It could also be used as the basis for your own Terraform project.

## License

This project is licensed under the [Apache 2.0 License](https://choosealicense.com/licenses/apache-2.0/).
For full details see the `LICENSE` file.
