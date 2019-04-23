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

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..

FMT=$(terraform fmt $REPO_ROOT)
if [ "$FMT" != "" ]; then
	echo "$FMT"
	exit 1
fi

mkdir $REPO_ROOT/verify-terraform
pushd $REPO_ROOT/verify-terraform
cp ../example/main.tf main.tf
cp ../example/variables.tf variables.tf
cp ../example/terraform.tfvars.example terraform.tfvars
# Comment out the requirement for a GCS backend so we can init and validate locally
sed -i.bak 's|backend "gcs" {}|# backend "gcs" {}|g' main.tf
terraform init
terraform validate
popd > /dev/null
rm -rf $REPO_ROOT/verify-terraform
