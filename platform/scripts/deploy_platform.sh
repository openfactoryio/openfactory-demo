#!/bin/bash
# ==============================================================================
# Deploy Demo-Factory Platform
# ------------------------------------------------------------------------------
# This deployment script handles both interactive use and CI/CD workflows.
#
# Key behaviors:
# 1. Environment setup:
#    - Saves original working directory and ensures we return to it on exit.
#    - Loads environment variables from `.ofaenv` and optional `.env`.
#
# 2. Kafka & Stream processing:
#    - Deploys Kafka cluster if not already running.
#    - Sets up ksqlDB topology via `ofa setup-kafka`.
#
# 3. Platform components:
#    - Fan-out layer
#    - OPC UA Connector
#    - Virtual Devices
#
# 4. Wait loops and health checks:
#    - Waits for OPC UA Coordinator to be up and running before continuing.
#    - Provides a spinning indicator and timeout handling.
#
# Notes for maintainers:
# - The script is designed to work both interactively and in CI.
# - All environment variables are expected to be loaded from `.ofaenv` / `.env`.
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

# Load environment variables from .ofaenv and .env in the project root
set -a
source .ofaenv
[ -f .env ] && source .env
set +a

# OpenFactory CLI
echo "⚙️  Setting up factory-manager ..."
docker pull ghcr.io/openfactoryio/ofa-cli:${OPENFACTORY_VERSION}
docker run --detach \
    --name factory-manager \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --group-add $(stat -c '%g' /var/run/docker.sock) \
    --env HOST_IP=${HOST_IP} \
    --volume $(pwd)/.ofaenv:/home/ofa/.ofaenv:ro \
    --volume $(pwd)/platform:/home/ofa/platform:ro \
    --volume $(pwd)/demo-factory:/home/ofa/demo-factory:ro \
    ghcr.io/openfactoryio/ofa-cli:${OPENFACTORY_VERSION}

# Check if Kafka cluster is already deployed
if docker compose -p kafka ps | grep -q 'Up'; then
    echo "🚀 Kafka cluster is already up and running"
else
  # Deploy Kafka cluster
  echo "🚀 Deploying Kafka cluster"
  docker compose -f platform/docker/kafka/docker-compose.yml up -d

  # Configure Kafka topics
  echo "⚙️  Setting up Kafka topics ..."
  platform/docker/kafka/create_topics.sh

  # Configure stream processing topology
  echo "🚀 Deploying Kafka stream processing topology"
  docker exec factory-manager ofa setup-kafka --ksqldb-server ${KSQLDB_URL}
fi

# Deploy Fan-out layer
echo "🚀 Deploying Fan-out layer"
docker compose -f platform/docker/fanout/docker-compose.yml up -d

# Deploy OPC UA Connector
echo "🚀 Deploying OPC UA Connector"
docker compose -f platform/docker/opcua-connector/docker-compose.yml up -d

# Deploy virtual Devices
platform/scripts/virtual_devices/deploy_virtual_devices.sh

# Wait until OPC UA Coordinator is up and running
YELLOW='\033[33m'
GREEN='\033[32m'
RESET='\033[0m'
spinchars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
i=0

TIMEOUT=60        # seconds
INTERVAL=0.1
START_TIME=$(date +%s)

while true; do
    # Check timeout
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        printf "\r%-60s\r" ""
        echo -e "${RED}✖${RESET} Timeout waiting for OPC UA Coordinator (${TIMEOUT}s)"
        exit 1
    fi

    # fetch registered Gateways
    response=$(curl -s "$HOST_IP:8000/gateways")

    # check if JSON contains a gateway_id
    if [ -n "$response" ] && echo "$response" | jq -e '.[0].gateway_id' >/dev/null 2>&1; then
        printf "\r%-60s\r" ""
        echo -e "${GREEN}✔${RESET} OPC UA Coordinator is up and running"
        break
    fi

    printf "\r${YELLOW}${spinchars[i % ${#spinchars[@]}]}${RESET} Waiting for OPC UA Coordinator..."
    i=$((i+1))
    sleep "$INTERVAL"
done
