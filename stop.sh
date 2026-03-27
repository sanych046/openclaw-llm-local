#!/bin/bash
echo "💤 Зупинка контейнерів..."
docker compose stop
echo "✅ Сервіси зупинені. Ресурси GPU/RAM вільні."
