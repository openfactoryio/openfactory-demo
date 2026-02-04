#!/bin/bash
# ==============================================================================
# Teardown Virtual Devices
# ==============================================================================

echo "🚀 Starting teardown of virtual device containers..."

# Virtual Temperature Controller
echo "🧹 Removing virtual-temp-controller..."
docker rm -f virtual-temp-controller

# Virtual DHT sensor 4841
echo "🧹 Removing virtual-dht-sensor-4841..."
docker rm -f virtual-dht-sensor-4841

# Virtual DHT sensor 4842
echo "🧹 Removing virtual-dht-sensor-4842..."
docker rm -f virtual-dht-sensor-4842

echo "✅ Virtual device teardown completed!"
