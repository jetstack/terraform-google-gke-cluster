# Copyright 2019 Jetstack Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Resource definitions for cluster and node pools

# Each argument is explained, most details are pulled from the Terraform
# documentation. Arguments set by input variables are documented in the
# variables.tf file.

terraform {
  # This module requires a terraform version >= 0.11 but < 0.12. This is
  # because the module is only tested with 0.11 ,and has not yet been upgraded
  # to use the new 0.12 syntax.
  required_version = "~> 0.11"
}

# Local values assign a name to an expression, that can then be used multiple
# times within a module. They are used here to determine the GCP region from
# the given location, which can be either a region or zone.
locals {
  gcp_location_parts = ["${split("-", var.gcp_location)}"]
  gcp_region         = "${local.gcp_location_parts[0]}-${local.gcp_location_parts[1]}"
}

# https://www.terraform.io/docs/providers/google/index.html
provider "google" {
  version = "2.5.1"
  project = "${var.gcp_project_id}"
  region  = "${local.gcp_region}"
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "cluster" {
  location = "${var.gcp_location}"

  name = "${var.cluster_name}"

  # The minimum version of the master. GKE will auto-update the master to new
  # versions, so this does not guarantee the current master version--use the
  # read-only master_version field to obtain that. If unset, the cluster's
  # version will be set by GKE to the version of the most recent official release
  # (which is not necessarily the latest version). Most users will find the
  # google_container_engine_versions data source useful - it indicates which
  # versions are available. If you intend to specify versions manually, the
  # docs describe the various acceptable formats for this field.
  min_master_version = "latest"

  maintenance_policy {
    daily_maintenance_window {
      start_time = "${var.daily_maintenance_window_start_time}"
    }
  }

  # A set of options for creating a private cluster.
  private_cluster_config {
    # Whether the master's internal IP address is used as the cluster endpoint.
    enable_private_endpoint = false

    # Whether nodes have internal IP addresses only. If enabled, all nodes are
    # given only RFC 1918 private addresses and communicate with the master via
    # private networking.
    enable_private_nodes = true

    master_ipv4_cidr_block = "${var.master_ipv4_cidr_block}"
  }

  # Configuration options for the NetworkPolicy feature.
  network_policy {
    # Whether network policy is enabled on the cluster. Defaults to false.
    # In GKE this also enables the ip masquerade agent
    # https://cloud.google.com/kubernetes-engine/docs/how-to/ip-masquerade-agent
    enabled = true

    # The selected network policy provider. Defaults to PROVIDER_UNSPECIFIED.
    provider = "CALICO"
  }

  master_auth {
    # Setting an empty username and password explicitly disables basic auth
    username = ""
    password = ""

    # Whether client certificate authorization is enabled for this cluster.
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # The configuration for addons supported by GKE.
  addons_config {
    # The status of the Kubernetes Dashboard add-on, which controls whether
    # the Kubernetes Dashboard is enabled for this cluster. It is enabled by default.
    kubernetes_dashboard {
      disabled = true
    }

    http_load_balancing {
      disabled = "${var.http_load_balancing_disabled}"
    }

    # Whether we should enable the network policy addon for the master. This must be
    # enabled in order to enable network policy for the nodes. It can only be disabled
    # if the nodes already do not have network policies enabled. Defaults to disabled;
    # set disabled = false to enable.
    network_policy_config {
      disabled = false
    }
  }

  network    = "${var.vpc_network_name}"
  subnetwork = "${var.vpc_subnetwork_name}"

  # Configuration for cluster IP allocation. As of now, only pre-allocated
  # subnetworks (custom type with secondary ranges) are supported. This will
  # activate IP aliases.
  ip_allocation_policy {
    # Whether alias IPs will be used for pod IPs in the cluster. Defaults to
    # true if the ip_allocation_policy block is defined, and to the API
    # default otherwise. Prior to June 17th 2019, the default on the API is
    # false; afterwards, it's true.
    use_ip_aliases = true

    cluster_secondary_range_name  = "${var.cluster_secondary_range_name}"
    services_secondary_range_name = "${var.services_secondary_range_name}"
  }

  # It's not possible to create a cluster with no node pool defined, but we
  # want to only use separately managed node pools. So we create the smallest
  # possible default node pool and immediately delete it.
  remove_default_node_pool = true

  # The number of nodes to create in this cluster (not including the Kubernetes master).
  initial_node_count = 1

  # The desired configuration options for master authorized networks. Omit the
  # nested cidr_blocks attribute to disallow external access (except the
  # cluster node IPs, which GKE automatically whitelists).
  master_authorized_networks_config {
    cidr_blocks = "${var.master_authorized_networks_cidr_blocks}"
  }

  # Change how long update operations on the cluster are allowed to take
  # before being considered to have failed. The default is 10 mins.
  # https://www.terraform.io/docs/configuration/resources.html#operation-timeouts
  timeouts {
    update = "20m"
  }
}

# https://www.terraform.io/docs/providers/google/r/container_node_pool.html
resource "google_container_node_pool" "node_pool" {
  # The location (region or zone) in which the cluster resides
  location = "${google_container_cluster.cluster.location}"

  count = "${length(var.node_pools)}"

  # The name of the node pool. Instance groups created will have the cluster
  # name prefixed automatically.
  name = "${lookup(var.node_pools[count.index], "name", format("%03d", count.index + 1))}-pool"

  # The cluster to create the node pool for.
  cluster = "${google_container_cluster.cluster.name}"

  initial_node_count = "${lookup(var.node_pools[count.index], "initial_node_count", 1)}"

  # Configuration required by cluster autoscaler to adjust the size of the node pool to the current cluster usage.
  autoscaling {
    # Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count.
    min_node_count = "${lookup(var.node_pools[count.index], "autoscaling_min_node_count", 2)}"

    # Maximum number of nodes in the NodePool. Must be >= min_node_count.
    max_node_count = "${lookup(var.node_pools[count.index], "autoscaling_max_node_count", 3)}"
  }

  # Node management configuration, wherein auto-repair and auto-upgrade is configured.
  management = {
    # Whether the nodes will be automatically repaired.
    auto_repair = "${lookup(var.node_pools[count.index], "auto_repair", true)}"

    # Whether the nodes will be automatically upgraded.
    auto_upgrade = "${lookup(var.node_pools[count.index], "auto_upgrade", true)}"
  }

  # Parameters used in creating the cluster's nodes.
  node_config {
    # The name of a Google Compute Engine machine type. Defaults to
    # n1-standard-1.
    machine_type = "${lookup(var.node_pools[count.index], "node_config_machine_type", "n1-standard-1")}"

    service_account = "${google_service_account.default.email}"

    # Size of the disk attached to each node, specified in GB. The smallest
    # allowed disk size is 10GB. Defaults to 100GB.
    disk_size_gb = "${lookup(var.node_pools[count.index], "node_config_disk_size_gb", 100)}"

    # Type of the disk attached to each node (e.g. 'pd-standard' or 'pd-ssd').
    # If unspecified, the default disk type is 'pd-standard'
    disk_type = "${lookup(var.node_pools[count.index], "node_config_disk_type", "pd-standard")}"

    # A boolean that represents whether or not the underlying node VMs are
    # preemptible. See the official documentation for more information.
    # Defaults to false.
    preemptible = "${lookup(var.node_pools[count.index], "node_config_preemptible", false)}"

    # The set of Google API scopes to be made available on all of the node VMs
    # under the "default" service account. These can be either FQDNs, or scope
    # aliases. The cloud-platform access scope authorizes access to all Cloud
    # Platform services, and then limit the access by granting IAM roles
    # https://cloud.google.com/compute/docs/access/service-accounts#service_account_permissions
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # The metadata key/value pairs assigned to instances in the cluster.
    metadata = {
      # https://cloud.google.com/kubernetes-engine/docs/how-to/protecting-cluster-metadata
      disable-legacy-endpoints = "true"
    }
  }

  # Change how long update operations on the node pool are allowed to take
  # before being considered to have failed. The default is 10 mins.
  # https://www.terraform.io/docs/configuration/resources.html#operation-timeouts
  timeouts {
    update = "20m"
  }
}
