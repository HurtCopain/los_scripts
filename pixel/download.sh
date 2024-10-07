#!/bin/bash

# SPDX-FileCopyrightText: 2022 The Calyx Institute
#
# SPDX-License-Identifier: Apache-2.0

#
# download:
#
#   Download Pixel factory images and OTA updates from Google
#
#
##############################################################################

export TMPDIR="$HOME/work/tmp"
mkdir -p "$TMPDIR"

### SET ###

# use bash strict mode
set -euo pipefail

### TRAPS ###

# trap signals for clean exit
trap 'exit $?' EXIT
trap 'error_m interrupted!' SIGINT

### CONSTANTS ###
readonly script_path="$(cd "$(dirname "$0")";pwd -P)"
readonly vars_path="${script_path}/../../../vendor/lineage/vars"

readonly home_work_dir="$HOME/work/pixel"
readonly work_dir="${WORK_DIR:-$home_work_dir}"

source "${vars_path}/pixels"

# Check if device is provided as an argument
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

# Download factory image function
download_factory_image() {
  local factory_dir="${work_dir}/${device}/${build_id}"
  
  # Ensure critical variables are set
  if [[ -z "${image_url:-}" || -z "${image_sha256:-}" || -z "${build_id:-}" ]]; then
    error_m "Missing required variables (image_url, image_sha256, or build_id) for device ${device}"
    exit 1
  fi

  mkdir -p "${factory_dir}"
  local output="${factory_dir}/$(basename "${image_url}")"

  # Download the factory image
  curl --http1.1 -C - -L -o "${output}" "${image_url}" || {
    error_m "Failed to download factory image for ${device}"
    exit 1
  }

  echo "${image_sha256} ${output}" | sha256sum --check --status || {
    error_m "SHA256 checksum failed for factory image ${output}"
    exit 1
  }
}

# Download OTA zip function
download_ota_zip() {
  local ota_dir="${work_dir}/${device}/${build_id}"
  
  # Ensure critical variables are set
  if [[ -z "${ota_url:-}" || -z "${ota_sha256:-}" || -z "${build_id:-}" ]]; then
    error_m "Missing required variables (ota_url, ota_sha256, or build_id) for device ${device}"
    exit 1
  fi

  mkdir -p "${ota_dir}"
  local output="${ota_dir}/$(basename "${ota_url}")"

  # Download the OTA zip
  curl --http1.1 -C - -L -o "${output}" "${ota_url}" || {
    error_m "Failed to download OTA update for ${device}"
    exit 1
  }

  echo "${ota_sha256} ${output}" | sha256sum --check --status || {
    error_m "SHA256 checksum failed for OTA update ${output}"
    exit 1
  }
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
  # Ensure work_dir is created
  mkdir -p "${work_dir}"

  # Download the factory image
  download_factory_image

  # Download OTA zip if needed
  if [[ -n "${needs_ota-}" ]]; then
    download_ota_zip
  fi
}

### RUN PROGRAM ###
main "${@}"
