#!/bin/bash

echo "======================================"
echo "    ⚙️  КЕРУВАННЯ КОНТЕЙНЕРАМИ         "
echo "======================================"
echo "1) 🚀 Запустити AI стек (start-interactive)"
echo "2) 📊 Перевірити статус (контейнери, моделі, об'єм даних)"
echo "3) ⏸  Призупинити (Pause) - тимчасове звільнення CPU"
echo "4) ▶  Відновити (Unpause) - відновлення роботи"
echo "5) ⏹  Зупинити (Stop) - вивантаження з VRAM"
echo "6) 🗑  Видалити контейнери (Down) - дані збережуться"
echo "7) 💣 ПОВНЕ ВИДАЛЕННЯ (знищення контейнерів та ollama_data)"
echo "8) ❌ Вихід"
read -p "Оберіть дію (1-8): " ACTION

case $ACTION in
    1)
        echo "🔄 Перехід до меню запуску..."
        
        # Перевірка наявності та створення директорії ollama_data
        if [ ! -d "ollama_data" ]; then
            echo "📁 Створення директорії ollama_data..."
            mkdir -p ollama_data
        fi

        # Розширений список моделей: базові, для програмування, розпізнавання зображень та роботи з документами.
        MODELS=(
            "llama3.1:8b"
            "llama3.2:3b"
            "qwen2.5:7b"
            "qwen2.5-coder:7b"
            "deepseek-coder-v2:16b"
            "gemma2:9b"
            "gemma4:e4b"
            "gemma4:26b-q4_k_m"
            "mistral:7b"
            "phi3.5:latest"
            "llava:7b"
            "minicpm-v:latest"
            "moondream:latest"
            "nomic-embed-text:latest"
        )
        DESCRIPTIONS=(
            "[Загальні питання / Агенти] ⭐ Класичний універсальний помічник"
            "[Надшвидке спілкування] Новітня легка (3B) оптимізована модель Meta"
            "[Потужний логік] 🥇 Вважається кращою загальною моделлю у своєму класі"
            "[Програмування (Код)] ⭐ Найкраща для роботи в агентах VS Code"
            "[Складне кодування] Повільніша за Qwen (частково вивантажується в RAM)"
            "[Творчість / Чат] Висока якість мови та логіки від Google"
            "[Ефективний чат] 🆕 Gemma 4 Edge 4B - швидкий та легкий для 8GB VRAM"
            "[Потужна логіка] 🆕 Gemma 4 26B MoE - просунута модель (тільки Q4_K_M для 8GB)"
            "[Альтернативний чат] Класична популярна базова модель"
            "[Швидкі відповіді] Працює надзвичайно швидко, мінімум ресурсів"
            "[Розпізнавання зображень] 👁️ Базовий аналіз фотографій та схем"
            "[Деталізований Vision] 👁️ Неймовірна деталізація та читання OCR"
            "[Дуже легкий Vision] 👁️ Швидке читання фото з мінімальними затратами"
            "[Вбудовування Embeddings] 📑 Обов'язкова для пошуку по документам (RAG)"
        )

        echo "--------------------------------------"
        echo "    🤖 МЕНЮ ЗАПУСКУ СТЕКУ             "
        echo "--------------------------------------"
        echo "1) Тільки Ollama (для VS Code / Агентів)"
        echo "2) Ollama + Open WebUI (Повний інтерфейс)"
        echo "3) Скасувати (Повернення)"
        read -p "Оберіть режим запуску: " MODE

        if [[ $MODE -eq 3 ]]; then 
            echo "🛑 Запуск скасовано."
        else
            echo ""
            echo "--- Оберіть модель для завантаження ---"
            for i in "${!MODELS[@]}"; do 
                printf "%-3s %-25s | %s\n" "$((i+1)))" "${MODELS[$i]}" "${DESCRIPTIONS[$i]}"
            done
            read -p "Введіть номер моделі: " M_CHOICE

            if [[ $M_CHOICE -ge 1 && $M_CHOICE -le ${#MODELS[@]} ]]; then
                MODEL=${MODELS[$((M_CHOICE-1))]}

                # Перевірка, чи вже запущений контейнер
                if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
                    echo ""
                    echo "⚠️  УВАГА: Контейнер 'ollama' вже працює!"
                    RUNNING_MODELS=$(docker exec ollama ollama ps 2>/dev/null | awk 'NR>1 {print $1}')
                    if [ -n "$RUNNING_MODELS" ]; then
                        MODELS_FMT=$(echo "$RUNNING_MODELS" | xargs | sed 's/ /, /g')
                        echo "🧠 Зараз у пам'яті працює: $MODELS_FMT"
                    fi
                    echo ""
                    echo "1) Зупинити попередній та запустити обраний новий ($MODEL)"
                    echo "2) Нічого не робити (скасувати)"
                    read -p "Оберіть варіант (1-2): " CONFLICT_ACT
                    if [[ "$CONFLICT_ACT" != "1" ]]; then
                        echo "🛑 Запуск скасовано."
                        exit 0
                    fi
                fi

                read -p "Введіть розмір контексту (num_ctx) [Enter для значення за замовчуванням]: " NUM_CTX_INPUT

                echo "♻️  Очищення старих контейнерів для уникнення конфлікту імен..."
                docker rm -f ollama open-webui 2>/dev/null

                if [[ $MODE -eq 1 ]]; then
                    echo "🚀 Запуск тільки Ollama..."
                    docker compose up -d ollama
                else
                    echo "🚀 Запуск повного стеку..."
                    docker compose up -d
                fi

                echo "⏳ Очікування ініціалізації (5 сек)..."
                sleep 5
                
                if [[ -z "$NUM_CTX_INPUT" ]]; then
                    echo "📦 Перевірка моделі $MODEL (із контекстом за замовчуванням)..."
                    docker exec -it ollama ollama run "$MODEL" ""
                else
                    echo "📦 Створення кастомної моделі на базі $MODEL із контекстом (num_ctx = $NUM_CTX_INPUT)..."
                    
                    # Формуємо ім'я для нової моделі з тегом контексту
                    if [[ "$MODEL" == *":"* ]]; then
                        REPO="${MODEL%%:*}"
                        TAG="${MODEL##*:}"
                        NEW_MODEL="${REPO}:${TAG}-ctx${NUM_CTX_INPUT}"
                    else
                        NEW_MODEL="${MODEL}:ctx${NUM_CTX_INPUT}"
                    fi

                    # Спочатку завантажуємо базову модель (якщо її немає, create видасть помилку)
                    docker exec -it ollama ollama pull "$MODEL"
                    
                    # Створюємо Modelfile і компілюємо нову модель
                    docker exec -i ollama sh -c "echo \"FROM $MODEL\" > /tmp/Modelfile && echo \"PARAMETER num_ctx $NUM_CTX_INPUT\" >> /tmp/Modelfile && ollama create \"$NEW_MODEL\" -f /tmp/Modelfile"
                    
                    echo "📦 Запуск моделі $NEW_MODEL..."
                    MODEL="$NEW_MODEL"
                    docker exec -it ollama ollama run "$MODEL" ""
                fi
                
                echo "✅ Всі сервіси запущені успішно!"
                [[ $MODE -eq 2 ]] && echo "🔗 WebUI: http://localhost:3000"
                echo "🔌 API для VS Code: http://localhost:11434"
            else
                echo "❌ Невірний вибір моделі."
            fi
        fi
        ;;
    2)
        echo "📊 Перевірка статусу системи..."
        echo "--------------------------------------"
        echo "[Статус контейнерів]"
        docker compose ps
        echo "--------------------------------------"
        echo "[Дані та моделі]"
        if [ -d "ollama_data" ]; then
            echo "✅ Робоча директорія 'ollama_data' існує."
            SIZE=$(du -sh ollama_data 2>/dev/null | cut -f1)
            echo "📦 Об'єм збережених даних: $SIZE"
            
            # Перевірка, чи запущений ollama для виводу списку моделей
            if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
                echo "📋 Список завантажених моделей:"
                docker exec ollama ollama list
            else
                echo "⚠️  Контейнер 'ollama' зараз не запущений. Запустіть його, щоб побачити перелік моделей."
            fi
        else
            echo "❌ Директорію 'ollama_data' ще не створено (дані відсутні)."
        fi
        echo "--------------------------------------"
        ;;
    3)
        echo "⏸ Призупинення контейнерів..."
        docker compose pause
        echo "✅ Контейнери призупинено."
        ;;
    4)
        echo "▶ Відновлення контейнерів..."
        docker compose unpause
        echo "✅ Контейнери відновлено."
        ;;
    5)
        echo "⏹ Зупинка контейнерів..."
        docker compose stop
        echo "✅ Контейнери зупинено. Відеопам'ять звільнено."
        ;;
    6)
        echo "🗑 Видалення контейнерів..."
        docker compose down
        echo "✅ Контейнери видалено. Дані в ollama_data збережено."
        ;;
    7)
        echo "⚠️  УВАГА: Ця дія повністю видалить всі контейнери, внутрішні томи Docker та робочу директорію ollama_data."
        echo "Всі завантажені моделі та налаштування Open WebUI будуть втрачені!"
        read -p "Ви СПРАВДІ хочете продовжити? (y/N): " CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            echo "💣 Видалення контейнерів та томів..."
            docker compose down -v
            echo "🗑 Видалення робочої директорії ollama_data..."
            rm -rf ollama_data
            echo "✅ Повне очищення успішно завершено."
        else
            echo "🛑 Дію скасовано. Ваші дані у безпеці."
        fi
        ;;
    8)
        exit 0
        ;;
    *)
        echo "❌ Невірний вибір. Спробуйте ще раз."
        ;;
esac
