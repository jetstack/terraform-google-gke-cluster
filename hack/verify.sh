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

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd )"

# Make temporary directory to use for testing and enter it
VERIFY_DIR="${REPO_ROOT}/verify"
mkdir -p "$VERIFY_DIR"
pushd "$VERIFY_DIR"

# Determine OS type and architecture to get the correct Terraform binary.
# Terrafom supports more platforms than are listed here, but only those used by
# the developers are included. We're open to PRs to add more.
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    TERRAFORM_OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    TERRAFORM_OS="darwin"
else
    echo "OS type not supported"
    exit 1
fi
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    TERRAFORM_ARCH="amd64"
elif [[ "$ARCH" == "i386" ]]; then
    TERRAFORM_ARCH="386"
else
    echo "Architecture not supported"
    exit 1
fi

# Checks the Terraform version used by the module, download the Terraform binary
# for that version
if grep "required_version.*0.12.*" "${REPO_ROOT}/main.tf"; then
    TERRAFORM_VERSION="0.12.4"
else
    echo "Terraform version is not supported or could not be found."
    exit 1
fi

TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_${TERRAFORM_OS}_${TERRAFORM_ARCH}.zip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"
# If the zip is already present don't download it again.
if [ ! -f ${TERRAFORM_ZIP} ]; then
    curl $TERRAFORM_URL -o $TERRAFORM_ZIP
fi
unzip -o $TERRAFORM_ZIP
chmod +x terraform
TERRAFORM="${VERIFY_DIR}/terraform"
$TERRAFORM version

# Capture the output of terraform fmt so that we can trigger the script to
# fail if formatting changes were made. terraform fmt does not consider
# applying formatting changes to be failure, however we want the files to be
# correctly formatted in version control.
FMT=$(${TERRAFORM} fmt $REPO_ROOT)
if [ "$FMT" != "" ]; then
    echo "$FMT"
    exit 1
fi

# Copy files from the example project
cp "${REPO_ROOT}/example/main.tf" main.tf
cp "${REPO_ROOT}/example/variables.tf" variables.tf
cp "${REPO_ROOT}/example/terraform.tfvars.example" terraform.tfvars
# Remove the requirement for a GCS backend so we can init and validate locally
perl -i -0pe 's/(\s*)backend "gcs" \{\n?\s*\n?\s*\}/\1# GCS bucket not used for testing/gms' main.tf
# Use the local version of the module, not the Terraform Registry version, and remove the version specification
perl -i -0pe 's/(\s*)source*\s*= "jetstack\/gke-cluster\/google"\n\s*version = ".*"/\1source = "..\/"/gms' main.tf

# Initialise and validate the generated test project
$TERRAFORM init
$TERRAFORM validate

# TODO: Set up a GCP project and service account to run the following section
# in automated testing.

# If SKIP_DESTROY is true then exit without destroying, this can be used to
# conduct more manual testing and experiments.
SKIP_DESTROY="${SKIP_DESTROY:-false}"

# To make Terraform plan and apply the generated test project the following
# environment variables are required:
# GOOGLE_APPLICATION_CREDENTIALS is the path of a key.json for a service account
# GCP_PROJECT_ID is the ID of a GCP project to use
if [ ! -z ${GCP_PROJECT_ID+x} ] || [ ! -z ${GOOGLE_APPLICATION_CREDENTIALS+x} ]; then
    echo $GCP_PROJECT_ID
    echo $GOOGLE_APPLICATION_CREDENTIALS
    sed -i.bak "s|my-project|$GCP_PROJECT_ID|g" terraform.tfvars
    $TERRAFORM  plan
    $TERRAFORM  apply -auto-approve
    if [ ! "$SKIP_DESTROY" == "true" ]; then
        $TERRAFORM destroy -auto-approve
    fi
else
    echo "Skipping terraform plan and apply as GCP_PROJECT_ID and GOOGLE_APPLICATION_CREDENTIALS not set."
fi

popd > /dev/null
# If SKIP_DESTROY is true then don't delete the project directory so that
# terraform destroy can still be run later for clean up.
if [ ! "$SKIP_DESTROY" == "true" ]; then
    rm -rf "$VERIFY_DIR"
fi
