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

# The ID of the project in which the resources belong.
variable "gcp_project_id" {
  type = "string"
}

# The name of the cluster, unique within the project and zone.
variable "cluster_name" {
  type = "string"
}

# The zone that the master and nodes specified in should be created in. If
# zone is set a zonal cluster will be created, even if region is also set.
variable "gcp_zone" {
  type    = "string"
  default = ""
}

# The region to create the cluster in. Master and nodes will be created in
# each of three zones of the region.
variable "gcp_region" {
  type    = "string"
  default = ""
}

# The start time of the 4 hour window for daily maintenance operations RFC3339
# format HH:MM, where HH : [00-23] and MM : [00-59] GMT.
variable "daily_maintenance_window_start_time" {
  type = "string"
}

# The list of node pool configurations, each should include:
#
# The name of the node pool, which will be suffixed with '-pool'. Defaults to
# pool number in the Terraform list, starting from 1.
# name
#
# The initial node count for the pool. Changing this will force recreation of
# the resource. Defaults to 1.
# initial_node_count
#
# Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count.
# Defaults to 2.
# autoscaling_min_node_count
#
# Maximum number of nodes in the NodePool. Must be >= min_node_count. Defaults
# to 3.
# autoscaling_max_node_count
#
# Whether the nodes will be automatically repaired. Defaults to 'true'.
# management_auto_repair
#
# Whether the nodes will be automatically upgraded. Defaults to 'true'.
# management_auto_upgrade
#
# The name of a Google Compute Engine machine type. Defaults to n1-standard-1.
# To create a custom machine type, value should be set as specified here:
# https://cloud.google.com/compute/docs/reference/rest/v1/instances#machineType
# node_config_machine_type
#
# Type of the disk attached to each node (e.g. 'pd-standard' or 'pd-ssd').
# Defaults to 'pd-standard'
# node_config_disk_type
#
# Size of the disk attached to each node, specified in GB. The smallest
# allowed disk size is 10GB. Defaults to 100GB.
# node_config_disk_size_gb
#
# Whether or not the underlying node VMs are preemptible. See the official
# documentation for more information. Defaults to false.
# https://cloud.google.com/kubernetes-engine/docs/how-to/preemptible-vms
# node_config_preemptible
variable "node_pools" {
  type = "list"
}

# The name of the Google Compute Engine network to which the cluster is
# connected.
variable "vpc_network_name" {
  type = "string"
}

# The name of the Google Compute Engine subnetwork in which the cluster's
# instances are launched.
variable "vpc_subnetwork_name" {
  type = "string"
}

variable "vpc_subnetwork_cidr_range" {
  type = "string"
}

# The name of the secondary range to be used as for the cluster CIDR block.
# The secondary range will be used for pod IP addresses. This must be an
# existing secondary range associated with the cluster subnetwork."
variable "cluster_secondary_range_name" {
  type = "string"
}

variable "cluster_secondary_range_cidr" {
  type = "string"
}

# The name of the secondary range to be used as for the services CIDR block.
# The secondary range will be used for service ClusterIPs. This must be an
# existing secondary range associated with the cluster subnetwork.
variable "services_secondary_range_name" {
  type = "string"
}

variable "services_secondary_range_cidr" {
  type = "string"
}

# The IP range in CIDR notation to use for the hosted master network. This 
# range will be used for assigning internal IP addresses to the master or set 
# of masters, as well as the ILB VIP. This range must not overlap with any 
# other ranges in use within the cluster's network.
variable "master_ipv4_cidr_block" {
  type    = "string"
  default = "172.16.0.0/28"
}

# Whether to create the IAM role for storage.objectViewer, required to access
# GCR for private container images.
variable "access_private_images" {
  type    = "string"
  default = "false"
}

# The status of the HTTP (L7) load balancing controller addon, which makes it 
# easy to set up HTTP load balancers for services in a cluster. It is enabled 
# by default; set disabled = true to disable.
variable "http_load_balancing_disabled" {
  type    = "string"
  default = "false"
}

# Defines up to 20 external networks that can access Kubernetes master
# through HTTPS.
variable "master_authorized_networks_cidr_blocks" {
  type = "list"

  default = [{
    # External network that can access Kubernetes master through HTTPS. Must
    # be specified in CIDR notation. This block should allow access from any
    # address, but is given explicitly to prevernt Google's defaults from
    # fighting with Terraform.
    cidr_block = "0.0.0.0/0"

    # Field for users to identify CIDR blocks.
    display_name = "default"
  }]
}
