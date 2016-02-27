#!/bin/bash
#########################################################
# utility functions
#########################################################
log_info() {
  echo "INFO: $1"
}

log_warn() {
  echo "WARN: $1"
}

log_error() {
  echo "ERROR: $1"
  exit 255
}
