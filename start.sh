#!/bin/bash
# Перевірка наявності та створення директорії ollama_data
if [ ! -d "ollama_data" ]; then
    echo "📁 Створення директорії ollama_data..."
    mkdir -p ollama_data
fi

echo "🚀 Запуск AI стеку (Ollama + Open WebUI)..."
docker compose up -d
echo "⏳ Очікування ініціалізації (10 сек)..."
sleep 10
docker compose ps
echo "✅ Готово! Адреса: http://localhost:3000"
