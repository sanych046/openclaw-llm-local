#!/bin/bash
echo "🧹 Complete removal of containers and network..."
docker compose down
echo "✅ Stack completely removed. Data (Volumes) preserved."
