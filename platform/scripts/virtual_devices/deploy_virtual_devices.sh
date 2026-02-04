#!/bin/bash
# ==============================================================================
# Deploy Virtual Devices
# ==============================================================================

echo "🚀 Starting deployment of virtual device containers..."

# Virtual Temperature Controller
echo "🚀 Deploying virtual-temp-controller..."
docker run --detach \
  --name virtual-temp-controller \
  --publish 4840:4840  \
  ghcr.io/openfactoryio/virtual-opcua-temp-controller:${OPENFACTORY_VERSION}

# Virtual DHT sensor 4841
echo "🚀 Deploying virtual-dht-sensor-4841..."
docker run --detach \
  --name virtual-dht-sensor-4841 \
  --publish 4841:4840 \
  --env NUM_SENSORS=1 \
  --env TEMP_SLEEP_AVG=0.5 \
  --env HUM_SLEEP_AVG=0.5 \
  ghcr.io/openfactoryio/virtual-opcua-sensor:${OPENFACTORY_VERSION}

# Virtual DHT sensor 4842
echo "🚀 Deploying virtual-dht-sensor-4842..."
docker run --detach \
  --name virtual-dht-sensor-4842 \
  --publish 4842:4840 \
  --env NUM_SENSORS=1 \
  --env TEMP_SLEEP_AVG=1.5 \
  --env HUM_SLEEP_AVG=1.5 \
  ghcr.io/openfactoryio/virtual-opcua-sensor:${OPENFACTORY_VERSION}

echo "✅ Virtual device deployment completed!"
