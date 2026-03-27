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

        MODELS=("llama3.1:8b" "qwen2.5-coder:7b" "deepseek-coder-v2:16b" "gemma2:9b" "mistral:7b" "phi3.5:latest")

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
            for i in "${!MODELS[@]}"; do echo "$((i+1))) ${MODELS[$i]}"; done
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

                echo "⏳ Очікування ініціалізації (5 сек)..."
                sleep 5
                
                echo "📦 Перевірка моделі $MODEL та налаштування контексту..."
                docker exec -it ollama ollama run $MODEL "/set parameter num_ctx 16384"
                docker exec -it ollama ollama run $MODEL ""
                
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
