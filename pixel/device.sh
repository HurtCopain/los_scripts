#!/bin/bash

# SPDX-FileCopyrightText: 2022-2023 The Calyx Institute
#
# SPDX-License-Identifier: Apache-2.0

#
# device:
#
#   Do it all for one device
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
readonly script_path="$(cd "$(dirname "$0")";pwd -P)"
readonly vars_path="${script_path}/../../../vendor/lineage/vars"
readonly top="${script_path}/../../.."

# Set TMPDIR to a folder in your home directory to avoid using /tmp
export TMPDIR="$HOME/work/tmp"
mkdir -p "$TMPDIR"

# Set WORK_DIR to a folder in your home directory, fallback to ~/work/pixel if not provided
readonly home_work_dir="$HOME/work/pixel"
mkdir -p "$home_work_dir"

readonly work_dir="${WORK_DIR:-$home_work_dir}"

source "${vars_path}/pixels"
source "${vars_path}/common"

## HELP MESSAGE (USAGE INFO)
# TODO

### FUNCTIONS ###

device() {
  local device="${1}"
  source "${vars_path}/${device}"
  local factory_dir="${work_dir}/${device}/${build_id}/factory/${device}_beta-${build_id,,}"

  # Ensure all downloaded files and extraction happens within $work_dir
  "${script_path}/download.sh" "${device}"  # Check download.sh for /tmp usage
  "${script_path}/extract-factory-image.sh" "${device}"  # Check extract-factory-image.sh for /tmp usage

  pushd "${top}"
  
  # Adjust path to accommodate devices that may be in subdirectories like caimito/komodo
  if [[ "$device" == "komodo" ]]; then
    device_path="device/google/caimito/komodo/extract-files.sh"
  else
    device_path="device/google/${device}/extract-files.sh"
  fi

  # Use the correct path for the extract-files.sh script
  "${device_path}" "${factory_dir}"
  
  popd

  if [[ "$os_branch" == "lineage-19.1" || "$os_branch" == "lineage-20.0" ]]; then
    "${script_path}/firmware.sh" "${device}"
  fi
}

# error message
# ARG1: error message for STDERR
# ARG2: error status
error_m() {
  echo "ERROR: ${1:-'failed.'}" 1>&2
  return "${2:-1}"
}

# print help message.
help_message() {
  echo "${help_message:-'No help available.'}"
}

main() {
  if [[ $# -eq 1 ]] ; then
    device "${1}"
  else
    error_m
  fi
}

### RUN PROGRAM ###

main "${@}"
