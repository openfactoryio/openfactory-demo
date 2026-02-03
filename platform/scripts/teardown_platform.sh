#!/bin/bash
# ==============================================================================
# Teardown Demo-Factory Platform
# ------------------------------------------------------------------------------
# This script handles the shutdown and cleanup of the Demo-Factory platform.
#
# Key behaviors:
# 1. Environment setup:
#    - Saves the original working directory and ensures we return to it on exit.
#    - Loads environment variables from `.ofaenv` and optional `.env`.
#
# 2. Project structure:
#    - Resolves the script directory and project root (two levels above script)
#      to ensure all relative paths work correctly.
#
# Notes for maintainers:
# - This script is intended for **interactive use**.
# - Environment variables from `.ofaenv` and `.env` must be correctly set.
# - The script uses a cleanup trap to return to the original directory
#   even if the script exits prematurely.
# - Teardown is sequential; ensure that dependent services are not in use
#   when running this script to prevent errors.
# - Additional platform components can be added by extending this script with
#   new `docker compose down` commands.
# ==============================================================================

# Remember where the user ran the script from
ORIGINAL_DIR="$(pwd)"

# Resolve the directory of this script (handles symlinks too)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root is two levels above:
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Trap ensures we always return to original dir,
# even if script exits early or errors occur
cleanup() {
    cd "$ORIGINAL_DIR"
}
trap cleanup EXIT

# Change to project root
cd "$PROJECT_ROOT" || exit 1

# Load environment variables
set -a
source .ofaenv
[ -f .env ] && source .env
set +a

# Shutdown factory manager
docker rm -f factory-manager

# Shutdown virtual sensors
docker rm -f virtual-temp-controller
docker rm -f virtual-dht-sensor-4841
docker rm -f virtual-dht-sensor-4842

# Shutdown OPCUA Connector
docker compose -f platform/docker/opcua-connector/docker-compose.yml down

# Shutdown Fan-out layer
docker compose -f platform/docker/fanout/docker-compose.yml down

# Shutdown Kafka cluster
docker compose -f platform/docker/kafka/docker-compose.yml down
