#!/bin/bash

echo "======================================"
echo "    ⚙️  CONTAINER MANAGEMENT           "
echo "======================================"
echo "1) 🚀 Start AI stack (start-interactive)"
echo "2) 📊 Check status (containers, models, data volume)"
echo "3) ⏸  Pause - temporarily free CPU"
echo "4) ▶  Unpause - resume operation"
echo "5) ⏹  Stop - offload from VRAM"
echo "6) 🗑  Remove containers (Down) - data preserved"
echo "7) 💣 FULL DELETION (destroy containers and ollama_data)"
echo "8) 🛠  Options (install drivers, etc.)"
echo "9) ❌ Exit"
read -p "Select an action (1-9): " ACTION

case $ACTION in
    1)
        echo "🔄 Proceeding to launch menu..."
        
        # Check for and create ollama_data directory
        if [ ! -d "ollama_data" ]; then
            echo "📁 Creating ollama_data directory..."
            mkdir -p ollama_data
        fi

        # Expanded list of models: base, coding, vision, and documents
        MODELS=(
            "llama3.1:8b"
            "llama3.2:3b"
            "qwen2.5:7b"
            "qwen2.5-coder:7b"
            "deepseek-coder-v2:16b"
            "gemma2:9b"
            "gemma4:e4b"
            "gemma4:12b"
            "gemma4:26b-q4_k_m"
            "hf.co/INSAIT-Institute/MamayLM-Gemma-3-12B-IT-v2.0-GGUF:Q4_K_M"
            "mistral:7b"
            "phi3.5:latest"
            "llava:7b"
            "minicpm-v:latest"
            "moondream:latest"
            "nomic-embed-text:latest"
        )
        DESCRIPTIONS=(
            "[General / Agents] ⭐ Classic universal assistant"
            "[Ultra-fast chat] Latest lightweight (3B) optimized Meta model"
            "[Powerful logic] 🥇 Considered best general model in its class"
            "[Programming (Code)] ⭐ Best for VS Code agents"
            "[Complex coding] Slower than Qwen (partially offloads to RAM)"
            "[Creativity / Chat] High language and logic quality from Google"
            "[Efficient chat] 🆕 Gemma 4 Edge 4B - fast and light for 8GB VRAM"
            "[Balanced chat] 🆕 Gemma 4 12B - balanced and capable mid-size model"
            "[Powerful logic] 🆕 Gemma 4 26B MoE - advanced model (Q4_K_M only for 8GB)"
            "[MamayLM] 🆕 MamayLM v2.0 (Gemma 3 12B) - Powerful language model"
            "[Alternative chat] Classic popular base model"
            "[Fast responses] Works extremely fast, minimum resources"
            "[Image Recognition] 👁️ Basic photo and diagram analysis"
            "[Detailed Vision] 👁️ Incredible detail and OCR reading"
            "[Very light Vision] 👁️ Fast photo reading with minimal cost"
            "[Embeddings] 📑 Essential for document search (RAG)"
        )

        echo "--------------------------------------"
        echo "    🤖 STACK LAUNCH MENU              "
        echo "--------------------------------------"
        echo "1) Ollama Only (for VS Code / Agents)"
        echo "2) Ollama + Open WebUI (Full Interface + Local Model)"
        echo "3) Open WebUI Only (Cloud Models Only, saves VRAM)"
        echo "4) Cancel (Return)"
        read -p "Select launch mode: " MODE

        if [[ $MODE -eq 4 ]]; then 
            echo "🛑 Launch cancelled."
        elif [[ $MODE -eq 3 ]]; then
            echo "♻️  Cleaning up old containers..."
            docker rm -f ollama open-webui 2>/dev/null
            echo "🚀 Launching Open WebUI for Cloud Models..."
            docker compose up -d
            echo "✅ Services launched! Ollama is idle (no local models loaded)."
            echo "🔗 WebUI: http://localhost:3000"
        else
            echo ""
            echo "--- Select a model to load ---"
            for i in "${!MODELS[@]}"; do 
                printf "%-3s %-25s | %s\n" "$((i+1)))" "${MODELS[$i]}" "${DESCRIPTIONS[$i]}"
            done
            read -p "Enter model number: " M_CHOICE

            if [[ $M_CHOICE -ge 1 && $M_CHOICE -le ${#MODELS[@]} ]]; then
                MODEL=${MODELS[$((M_CHOICE-1))]}

                # Check if container is already running
                if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
                    echo ""
                    echo "⚠️  WARNING: 'ollama' container is already running!"
                    RUNNING_MODELS=$(docker exec ollama ollama ps 2>/dev/null | awk 'NR>1 {print $1}')
                    if [ -n "$RUNNING_MODELS" ]; then
                        MODELS_FMT=$(echo "$RUNNING_MODELS" | xargs | sed 's/ /, /g')
                        echo "🧠 Currently running in memory: $MODELS_FMT"
                    fi
                    echo ""
                    echo "1) Stop previous and launch selected new ($MODEL)"
                    echo "2) Do nothing (cancel)"
                    read -p "Select option (1-2): " CONFLICT_ACT
                    if [[ "$CONFLICT_ACT" != "1" ]]; then
                        echo "🛑 Launch cancelled."
                        exit 0
                    fi
                fi

                read -p "Enter context size (num_ctx) [Enter for default]: " NUM_CTX_INPUT

                echo "♻️  Cleaning up old containers to avoid name conflicts..."
                docker rm -f ollama open-webui 2>/dev/null

                if [[ $MODE -eq 1 ]]; then
                    echo "🚀 Launching Ollama only..."
                    docker compose up -d ollama
                else
                    echo "🚀 Launching full stack..."
                    docker compose up -d
                fi

                echo "⏳ Waiting for initialization (5 sec)..."
                sleep 5
                
                if [[ -z "$NUM_CTX_INPUT" ]]; then
                    echo "📦 Checking model $MODEL (with default context)..."
                    docker exec -it ollama ollama run "$MODEL" ""
                else
                    echo "📦 Creating custom model based on $MODEL with context (num_ctx = $NUM_CTX_INPUT)..."
                    
                    # Format name for new model with context tag
                    if [[ "$MODEL" == *":"* ]]; then
                        REPO="${MODEL%%:*}"
                        TAG="${MODEL##*:}"
                        NEW_MODEL="${REPO}:${TAG}-ctx${NUM_CTX_INPUT}"
                    else
                        NEW_MODEL="${MODEL}:ctx${NUM_CTX_INPUT}"
                    fi

                    # First pull base model (if not present, create will fail)
                    docker exec -it ollama ollama pull "$MODEL"
                    
                    # Create Modelfile and compile new model
                    docker exec -i ollama sh -c "echo \"FROM $MODEL\" > /tmp/Modelfile && echo \"PARAMETER num_ctx $NUM_CTX_INPUT\" >> /tmp/Modelfile && ollama create \"$NEW_MODEL\" -f /tmp/Modelfile"
                    
                    echo "📦 Launching model $NEW_MODEL..."
                    MODEL="$NEW_MODEL"
                    docker exec -it ollama ollama run "$MODEL" ""
                fi
                
                echo "✅ All services launched successfully!"
                [[ $MODE -eq 2 ]] && echo "🔗 WebUI: http://localhost:3000"
                echo "🔌 API for VS Code: http://localhost:11434"
            else
                echo "❌ Invalid model selection."
            fi
        fi
        ;;
    2)
        echo "📊 Checking system status..."
        echo "--------------------------------------"
        echo "[Container Status]"
        docker compose ps
        echo "--------------------------------------"
        echo "[Data and Models]"
        if [ -d "ollama_data" ]; then
            echo "✅ Working directory 'ollama_data' exists."
            SIZE=$(du -sh ollama_data 2>/dev/null | cut -f1)
            echo "📦 Volume of saved data: $SIZE"
            
            # Check if ollama is running to list models
            if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
                echo "📋 List of downloaded models:"
                docker exec ollama ollama list
            else
                echo "⚠️  'ollama' container is currently not running. Start it to see the list of models."
            fi
        else
            echo "❌ Directory 'ollama_data' is not created yet (no data)."
        fi
        echo "--------------------------------------"
        ;;
    3)
        echo "⏸ Pausing containers..."
        docker compose pause
        echo "✅ Containers paused."
        ;;
    4)
        echo "▶ Unpausing containers..."
        docker compose unpause
        echo "✅ Containers resumed."
        ;;
    5)
        echo "⏹ Stopping containers..."
        docker compose stop
        echo "✅ Containers stopped. Video memory freed."
        ;;
    6)
        echo "🗑 Removing containers..."
        docker compose down
        echo "✅ Containers removed. Data in ollama_data preserved."
        ;;
    7)
        echo "⚠️  WARNING: This action will completely remove all containers, internal Docker volumes, and the ollama_data working directory."
        echo "All downloaded models and Open WebUI settings will be lost!"
        read -p "Are you SURE you want to continue? (y/N): " CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            echo "💣 Removing containers and volumes..."
            docker compose down -v
            echo "🗑 Removing ollama_data working directory..."
            rm -rf ollama_data
            echo "✅ Complete cleanup finished successfully."
        else
            echo "🛑 Action cancelled. Your data is safe."
        fi
        ;;
    8)
        echo "--------------------------------------"
        echo "    🛠  OPTIONS AND SETTINGS          "
        echo "--------------------------------------"
        echo "1) 📥 Install NVIDIA drivers and CUDA (for Ubuntu 26.04)"
        echo "2) 🔄 Update components (docker compose pull)"
        echo "3) ☁️  Configure Cloud APIs (Gemini, Qwen)"
        echo "4) 🔙 Return to main menu"
        read -p "Select action (1-4): " OPT_ACTION
        case $OPT_ACTION in
            1)
                echo "🚀 Installing NVIDIA drivers (550 series) and CUDA Toolkit for Ubuntu 26.04..."
                sudo apt update
                sudo apt install -y ubuntu-drivers-common
                sudo ubuntu-drivers autoinstall
                sudo apt install -y nvidia-cuda-toolkit
                echo "✅ Installation complete. A system reboot is recommended to apply changes."
                ;;
            2)
                echo "🔄 Updating Docker images (Ollama & WebUI)..."
                docker compose pull
                echo "✅ Update complete. If containers are running, you may need to stop and start them to apply the updates."
                ;;
            3)
                while true; do
                    echo "--------------------------------------"
                    echo "    ☁️  CLOUD API CONFIGURATION      "
                    echo "--------------------------------------"
                    echo "1) 👁️  View Current Keys"
                    echo "2) ➕  Add/Edit Gemini API Key"
                    echo "3) ➕  Add/Edit Qwen (DashScope) API Key"
                    echo "4) 🗑️  Remove Gemini API Key"
                    echo "5) 🗑️  Remove Qwen (DashScope) API Key"
                    echo "6) 🔙 Return to Options Menu"
                    read -p "Select action (1-6): " API_ACTION
                    
                    touch .env
                    
                    case $API_ACTION in
                        1)
                            echo "--- Current Keys ---"
                            if grep -q "^GEMINI_API_KEY=" .env; then
                                KEY=$(grep "^GEMINI_API_KEY=" .env | cut -d '=' -f 2)
                                if [ -n "$KEY" ]; then
                                    MASKED="${KEY:0:5}***${KEY: -4}"
                                    echo "Gemini: $MASKED"
                                else
                                    echo "Gemini: Not Set"
                                fi
                            else
                                echo "Gemini: Not Set"
                            fi
                            
                            if grep -q "^OPENAI_API_KEYS=" .env; then
                                KEY=$(grep "^OPENAI_API_KEYS=" .env | cut -d '=' -f 2)
                                if [ -n "$KEY" ]; then
                                    MASKED="${KEY:0:5}***${KEY: -4}"
                                    echo "Qwen (DashScope): $MASKED"
                                else
                                    echo "Qwen (DashScope): Not Set"
                                fi
                            else
                                echo "Qwen (DashScope): Not Set"
                            fi
                            echo "--------------------"
                            ;;
                        2)
                            read -p "Enter Gemini API Key: " GEMINI_KEY
                            if [ -n "$GEMINI_KEY" ]; then
                                if grep -q "^GEMINI_API_KEY=" .env; then
                                    sed -i "s/^GEMINI_API_KEY=.*/GEMINI_API_KEY=$GEMINI_KEY/" .env
                                else
                                    echo "GEMINI_API_KEY=$GEMINI_KEY" >> .env
                                fi
                                echo "✅ Gemini API key updated."
                            else
                                echo "❌ Key cannot be empty. Use 'Remove' to delete a key."
                            fi
                            ;;
                        3)
                            read -p "Enter DashScope (Qwen) API Key: " QWEN_KEY
                            if [ -n "$QWEN_KEY" ]; then
                                if grep -q "^OPENAI_API_KEYS=" .env; then
                                    sed -i "s/^OPENAI_API_KEYS=.*/OPENAI_API_KEYS=$QWEN_KEY/" .env
                                else
                                    echo "OPENAI_API_KEYS=$QWEN_KEY" >> .env
                                fi
                                
                                if grep -q "^OPENAI_API_BASE_URLS=" .env; then
                                    sed -i "s|^OPENAI_API_BASE_URLS=.*|OPENAI_API_BASE_URLS=https://dashscope-intl.aliyuncs.com/compatible-mode/v1|" .env
                                else
                                    echo "OPENAI_API_BASE_URLS=https://dashscope-intl.aliyuncs.com/compatible-mode/v1" >> .env
                                fi
                                echo "✅ Qwen (DashScope) API key updated."
                            else
                                echo "❌ Key cannot be empty. Use 'Remove' to delete a key."
                            fi
                            ;;
                        4)
                            sed -i '/^GEMINI_API_KEY=/d' .env
                            echo "✅ Gemini API key removed."
                            ;;
                        5)
                            sed -i '/^OPENAI_API_KEYS=/d' .env
                            sed -i '/^OPENAI_API_BASE_URLS=/d' .env
                            echo "✅ Qwen (DashScope) API key removed."
                            ;;
                        6)
                            echo "🔙 Returning to Options Menu..."
                            break
                            ;;
                        *)
                            echo "❌ Invalid selection."
                            ;;
                    esac
                    echo ""
                done
                ;;
            4)
                exec "$0"
                ;;
            *)
                echo "❌ Invalid selection."
                ;;
        esac
        ;;
    9)
        exit 0
        ;;
    *)
        echo "❌ Invalid selection. Please try again."
        ;;
esac
