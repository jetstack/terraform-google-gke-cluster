#!/usr/bin/env bash

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

# Make the zonal cluster resource definiton from the regional cluster resource
# definition. This helps to keep the two definitions the same, except for the
# presence of the region or zone property.

set -o errexit
set -o nounset
set -o pipefail

cp gke/regional.tf gke/zonal.tf

# Replace regional first or you'll end up with 'zoneal'
sed -i.bak 's|regional|zonal|g' gke/zonal.tf
sed -i.bak 's|region|zone|g' gke/zonal.tf

# Update the expression used to set count
sed -i.bak 's|var.gcp_zone == ""|var.gcp_zone != ""|g' gke/zonal.tf

# Remove sed backup
rm gke/zonal.tf.bak
