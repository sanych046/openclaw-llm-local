#!/bin/bash

# Список доступних моделей
MODELS=(
    "llama3.1:8b"
    "qwen2.5-coder:7b"
    "deepseek-coder-v2:16b"
    "gemma2:9b"
    "mistral:7b"
    "phi3.5:latest"
)

echo "======================================"
echo "    🤖 КЕРУВАННЯ AI СТЕКОМ           "
echo "======================================"
echo "1) Тільки Ollama (для VS Code / Агентів)"
echo "2) Ollama + Open WebUI (Повний інтерфейс)"
echo "3) Вихід"
read -p "Оберіть режим запуску: " MODE

if [[ $MODE -eq 3 ]]; then exit 0; fi

echo ""
echo "--- Оберіть модель для завантаження ---"
for i in "${!MODELS[@]}"; do
    echo "$((i+1))) ${MODELS[$i]}"
done
read -p "Введіть номер моделі: " M_CHOICE

if [[ $M_CHOICE -ge 1 && $M_CHOICE -le ${#MODELS[@]} ]]; then
    MODEL=${MODELS[$((M_CHOICE-1))]}

    if [[ $MODE -eq 1 ]]; then
        echo "🚀 Запуск тільки Ollama..."
        docker compose up -d ollama
    else
        echo "🚀 Запуск повного стеку..."
        docker compose up -d
    fi

    echo "⏳ Очікування ініціалізації..."
    sleep 5
    
    echo "📦 Перевірка моделі $MODEL та налаштування контексту..."
    # Запускаємо модель з параметром num_ctx 16384
    docker exec -it ollama ollama run $MODEL "/set parameter num_ctx 16384"
    # Одразу виходимо, щоб залишити її в пам'яті
    docker exec -it ollama ollama run $MODEL ""
    
    echo "✅ Готово!"
    [[ $MODE -eq 2 ]] && echo "🔗 WebUI: http://localhost:3000"
    echo "🔌 API для VS Code: http://localhost:11434"
else
    echo "❌ Невірний вибір моделі."
fi
