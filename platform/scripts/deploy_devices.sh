#!/bin/bash
# ==============================================================================
# Deploy devices of Demo-Factory
# ------------------------------------------------------------------------------
# This deployment script handles the provisioning of physical and virtual devices
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

echo "✅ Container '$OFA_CONTAINER_NAME' is running. Starting deployment..."
echo

set -e  # Exit immediately if any command fails

# Deploy devices from Assembly on OpenFactory
echo "🚀 Deploying Assembly area assets to OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device up demo-factory/assembly

# Deploy Machining/WC001 on OpenFactory
echo "🚀 Deploying Machining/WC001 assets to OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device up demo-factory/machining/WC001

# Deploy Machining/WC002 on OpenFactory
echo "🚀 Deploying Machining/WC002 assets to OpenFactory"
docker exec "$OFA_CONTAINER_NAME" ofa device up demo-factory/machining/WC002

echo
echo "✅ Deployment completed successfully!"
