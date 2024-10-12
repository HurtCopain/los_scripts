#!/bin/bash

# SPDX-FileCopyrightText: 2022-2023 The Calyx Institute
#
# SPDX-License-Identifier: Apache-2.0

#
# extract-factory-image:
#
#   Extract Pixel factory images
#
#
##############################################################################

### SET ###

# use bash strict mode
set -euo pipefail

### TRAPS ###

# trap signals for clean exit
trap 'exit $?' EXIT
trap 'error_m interrupted!' SIGINT

### CONSTANTS ###
readonly script_path="$(cd "$(dirname "$0")"; pwd -P)"
readonly vars_path="${script_path}/../../../vendor/lineage/vars"

readonly home_work_dir="$HOME/work/pixel"
readonly work_dir="${WORK_DIR:-$home_work_dir}"

# Source pixel devices
source "${vars_path}/pixels"

# Ensure device argument is provided
if [[ $# -ne 1 ]]; then
  echo "ERROR: Device argument is required." 1>&2
  exit 1
fi

readonly device="${1}"

# Source device-specific variables
source "${vars_path}/${device}"

## HELP MESSAGE (USAGE INFO)
# TODO

### FUNCTIONS ###

extract_factory_image() {
  # Ensure critical variables are set
  if [[ -z "${build_id:-}" || -z "${image_url:-}" || -z "${image_sha256:-}" ]]; then
    error_m "Missing required variables (build_id, image_url, or image_sha256) for device ${device}"
    exit 1
  fi

  local factory_dir="${work_dir}/${device}/${build_id}/factory"
  
  # Skip extraction if factory directory already exists
  if [[ -d "${factory_dir}" ]]; then
    echo "Skipping factory image extraction, ${factory_dir} already exists"
    exit
  fi

  mkdir -p "${factory_dir}"
  
  local factory_zip="${work_dir}/${device}/${build_id}/$(basename "${image_url}")"
  
  # Check the integrity of the downloaded image file
  echo "${image_sha256} ${factory_zip}" | sha256sum --check --status || {
    error_m "SHA256 checksum failed for ${factory_zip}"
    exit 1
  }

  # Unzip the factory image
  pushd "${factory_dir}" > /dev/null
  unzip -o "${factory_zip}" || {
    error_m "Failed to unzip ${factory_zip}"
    exit 1
  }

  # Extract inner image ZIP
  pushd "${device}_beta-${build_id,,}" > /dev/null
  unzip -o "image-${device}_beta-${build_id,,}.zip" || {
    error_m "Failed to unzip image-${device}_beta-${build_id,,}.zip"
    exit 1
  }
  popd > /dev/null
  popd > /dev/null
}

# Error message function
# ARG1: error message for STDERR
# ARG2: error status
error_m() {
  echo "ERROR: ${1:-'failed.'}" 1>&2
  return "${2:-1}"
}

# Print help message.
help_message() {
  echo "${help_message:-'No help available.'}"
}

# Main function
main() {
  extract_factory_image
}

### RUN PROGRAM ###
main "${@}"
