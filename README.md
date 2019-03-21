# GKE Terraform Module

A Terraform module to create a best-practise Google Kubernetes Engine (GKE) cluster.

It is designed to be used by Jetstack customers to make it easier for them to create clusters that are secure and follow Jetstack recommendations. It gives them flexibility with certain properties, such as Pod CIDR, regional or zonal, etc. But fixes other properties that could lead to insecurity, such as disabling the Kubernetes dashboard, enabling private cluster, etc.

## Customisable Properties

This module features many customisable properties, including:

-  GCP project ID
-  Cluster name
-  Cluster region
-  Cluster zone (for a zonal cluster)
-  Maintenance window start time
-  Node pools
   -  Name
   -  Initial size
   -  Machine type
   -  Disk type and size
   -  Autoscaling min and max
-  VPC network and subnetwork
-  Pod and Service CIDRs

## Fixed Properties

Many of the properties of this module are fixed as they are the Jetstack recommended best-practice settings. This includes:

-  Setting the master version to latest to get the most recent official Kubernetes version
-  Enabling node auto-upgrade and auto-repair so that nodes are up to date and working
-  Setting the OAuth scope of nodes to `cloud-platform` to manage permissions with IAM
-  Creating an IAM service account for nodes with the minimum required roles
-  Setting the cluster nodes to private so they aren't reachable externally
-  Enablbling HTTP load balancing so that the Google Cloud Load Balancer can be used as an Ingress
-  Disabling basic authentication as it is deprecated and less secure
-  Disabling Kubernetes dashboard as it's also depracated and less secure, the Google Cloud Console should be used instead
-  Disabling client certificate issuing as it is deprecated and less secure
-  Use of VPC native networking using a network and subnetwork to be specified
-  Enabling network policy to allow restrictions to be placed on how pods can communicate
-  Disabling the default node pool and creating one or more new pools with Terraform for easier management

## Usage

The module itself is located in the `gke/` directory and is designed to be used as part of a larger Terraform project. There is also a minimal example project in the `example/` directory which can be used to show the GKE module in use.
