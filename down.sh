cat << 'EOF' > down.sh
#!/bin/bash
echo "🧹 Повне видалення контейнерів та мережі..."
docker compose down
echo "✅ Стек повністю прибрано. Дані (Volumes) збережено."
EOF
