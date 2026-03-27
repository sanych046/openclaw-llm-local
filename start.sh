cat << 'EOF' > start.sh
#!/bin/bash
echo "🚀 Запуск AI стеку (Ollama + Open WebUI)..."
docker compose up -d
echo "⏳ Очікування ініціалізації (10 сек)..."
sleep 10
docker compose ps
echo "✅ Готово! Адреса: http://localhost:3000"
EOF
