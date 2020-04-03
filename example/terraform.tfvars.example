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

gcp_project_id = "my-project"

cluster_name = "my-cluster"

# The location (region or zone) in which the cluster will be created. If you
# specify a zone (such as us-central1-a), the cluster will be a zonal cluster.
# If you specify a region (such as us-west1), the cluster will be a regional
# cluster.
gcp_location = "europe-west1"

daily_maintenance_window_start_time = "03:00"

node_pools = [
  {
    name                       = "default"
    initial_node_count         = 1
    autoscaling_min_node_count = 2
    autoscaling_max_node_count = 3
    management_auto_upgrade    = true
    management_auto_repair     = true
    node_config_machine_type   = "n1-standard-1"
    node_config_disk_type      = "pd-standard"
    node_config_disk_size_gb   = 100
    node_config_preemptible    = false
  },
]

vpc_network_name = "vpc-network"

vpc_subnetwork_name = "vpc-subnetwork"

vpc_subnetwork_cidr_range = "10.0.16.0/20"

cluster_secondary_range_name = "pods"

cluster_secondary_range_cidr = "10.16.0.0/12"

services_secondary_range_name = "services"

services_secondary_range_cidr = "10.1.0.0/20"

master_ipv4_cidr_block = "172.16.0.0/28"

access_private_images = "false"

http_load_balancing_disabled = "false"

master_authorized_networks_cidr_blocks = [
  {
    cidr_block = "0.0.0.0/0"

    display_name = "default"
  },
]
