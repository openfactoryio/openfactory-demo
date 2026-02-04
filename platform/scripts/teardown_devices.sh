#!/bin/bash
# ==============================================================================
# Teardown devices of Demo-Factory
# ------------------------------------------------------------------------------
# This teardown script handles the removal of physical and virtual devices
# for the Demo-Factory within OpenFactory.
#
# Notes:
# - This script assumes factory-manager container is available
# ==============================================================================

OFA_CONTAINER_NAME="factory-manager"

echo "🔍 Checking if container '$OFA_CONTAINER_NAME' exists and is running..."

if ! docker ps --format '{{.Names}}' | grep -q "^${OFA_CONTAINER_NAME}$"; then
  echo "❌ Error: Required container '$OFA_CONTAINER_NAME' is not running or does not exist."
  echo "👉 Please start it first (e.g. 'docker start $OFA_CONTAINER_NAME') and re-run this script."
  exit 1
fi

echo "✅ Container '$OFA_CONTAINER_NAME' is running. Starting teardown..."
echo

set -e  # Exit immediately if any command fails

# Teardown devices from Assembly on OpenFactory
echo "🧹 Tearing down Assembly area assets from OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device down demo-factory/assembly

# Teardown Machining/WC001 on OpenFactory
echo "🧹 Tearing down Machining/WC001 assets from OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device down demo-factory/machining/WC001

# Teardown Machining/WC002 on OpenFactory
echo "🧹 Tearing down Machining/WC002 assets from OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device down demo-factory/machining/WC002

echo
echo "✅ Teardown completed successfully!"
