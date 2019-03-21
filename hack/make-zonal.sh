#!/usr/bin/env bash

# Make the zonal cluster resource definiton from the regional cluster resource
# definition. This helps to keep the two definitions the same, except for the
# presence of the region or zone property.

set -e

cp gke/regional.tf gke/zonal.tf

# Replace regional first or you'll end up with 'zoneal'
sed -i.bak 's|regional|zonal|g' gke/zonal.tf
sed -i.bak 's|region|zone|g' gke/zonal.tf

# Update the expression used to set count
sed -i.bak 's|var.gcp_zone == ""|var.gcp_zone != ""|g' gke/zonal.tf

# Remove sed backup
rm gke/zonal.tf.bak
