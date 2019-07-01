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
set -o xtrace

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..

# Capture the output of terraform fmt so that we can trigger the script to
# fail if formatting changes were made. terraform fmt does not consider
# applying formatting changes to be failure, however we want the files to be
# correctly formatted in version control.
FMT=$(terraform fmt $REPO_ROOT)
if [ "$FMT" != "" ]; then
	echo "$FMT"
	exit 1
fi

mkdir -p $REPO_ROOT/verify-terraform
pushd $REPO_ROOT/verify-terraform
cp ../example/main.tf main.tf
cp ../example/variables.tf variables.tf
cp ../example/terraform.tfvars.example terraform.tfvars
# Comment out the requirement for a GCS backend so we can init and validate locally
sed -i.bak 's|backend "gcs" {}|# backend "gcs" {}|g' main.tf
# Use the local version of the module, not the Terraform Registry version
sed -i.bak 's|source\s=\s"jetstack/gke-cluster/google"|source\s=\s"../"|g' main.tf
sed -i.bak 's|"jetstack/gke-cluster/google"|"../"|g' main.tf

terraform init
terraform validate

# TODO: Set up a GCP project and service account to run the following section
# in automated testing. 

# To make Terraform plan and apply the the following env vars are required:
# GOOGLE_APPLICATION_CREDENTIALS is the path of a key.json for a service account
# GCP_PROJECT_ID is the ID of a GCP project to use
if [ ! -z ${GCP_PROJECT_ID+x} ] || [ ! -z ${GOOGLE_APPLICATION_CREDENTIALS+x} ]; then
	echo $GCP_PROJECT_ID
	echo $GOOGLE_APPLICATION_CREDENTIALS
	sed -i.bak "s|my-project|$GCP_PROJECT_ID|g" terraform.tfvars
	terraform plan
	terraform apply -auto-approve
	terraform destroy -auto-approve
else
	echo "Skipping Terraform plan and apply as GCP_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS not set."
fi

popd > /dev/null
rm -rf $REPO_ROOT/verify-terraform
