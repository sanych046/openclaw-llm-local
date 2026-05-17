# 🤖 Local AI Stack: Ollama + Open WebUI

This project allows you to deploy a personal AI environment on your local machine using Docker. The stack is optimized for NVIDIA GPUs (tested on RTX 5060 8GB) and supports both local models and integration with cloud APIs.

## 🚀 Purpose
* **Private Chat:** Use LLMs without sending data to the cloud.
* **Development Agent:** Connect local models to VS Code (via Kilo, Continue, etc.).
* **Multimodality:** Document analysis (PDF, Text) and coding assistance.
* **Flexibility:** Fast switching between Llama 3.1, Qwen 2.5 Coder, Gemma 2, and more.

---

## 🛠 Prerequisites

**System Requirements:** The project is optimized and tested for **Ubuntu 26.04**.

1.  **NVIDIA Drivers:** Ensure up-to-date drivers are installed (version 550+). For automatic installation of drivers and CUDA in Ubuntu 26.04, you can use the "Options" menu in the `manage.sh` script.
2.  **Docker & Docker Compose:** Must be installed on your system.
3.  **NVIDIA Container Toolkit:** Required for passing through the GPU to Docker.

    ```bash
    # Verify installation
    nvidia-smi
    docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu26.04 nvidia-smi
    ```

---

## 📂 Project Structure
* `docker-compose.yml` — Service descriptions and GPU configuration.
* `stop.sh` — Quick stop with VRAM offloading.
* `down.sh` — Complete removal of containers.
* `manage.sh` — Main interactive script for launching the stack and fully managing containers.
* `ollama_data/` — Storage location for downloaded models (Docker Volume).

---

## 🕹 Usage

### 1. Initialize Scripts
Before the first run, make the scripts executable:

```bash
chmod +x *.sh
```

### 2. Launch Stack
Start the main interactive menu:

```bash
./manage.sh
```
Choose **option 1 (Start AI stack)**. You will then be prompted for:
- **Operating Mode:** Ollama only (for VS Code) or full mode with Open WebUI.
- **AI Model:** Select from the list with descriptions.
- **Context Size (num_ctx).**

### 3. Access Interfaces
* **Web Interface:** [http://localhost:3000](http://localhost:3000)
* **Ollama API:** [http://localhost:11434](http://localhost:11434)

### 4. Container Management
Use the universal interactive script `manage.sh` for effective container management. It provides a convenient action menu:
- **Pause** or **Unpause** containers to temporarily free PC resources.
- **Stop** containers.
- **Remove (Down)** containers (model data and settings are preserved).
- **Full Deletion** destroying all data, containers, and working files (deletes `ollama_data`). This action requires additional user confirmation.

Launch management menu:

```bash
./manage.sh
```

---

## 💻 Models and Compatibility (for 8GB VRAM)

| Model | Purpose | Recommendation |
| :--- | :--- | :--- |
| **Qwen 2.5 7B** | Basic Universal | 🥇 Currently the best universal model in this class |
| **Qwen 2.5 Coder 7B** | Programming (Code) | ⭐ Best for VS Code agents |
| **Llama 3.1 8B** | General Questions / Agents | ⭐ Classic powerful universal assistant |
| **Llama 3.2 3B** | Ultra-fast Tasks | Extremely optimized lightweight Meta model |
| **Gemma 2 9B** | Creativity / Chat | High language and logic quality (from Google) |
| **Gemma 4 E4B** | 🆕 Efficient Chat | Latest Edge model, perfect for 8GB VRAM |
| **Gemma 4 26B MoE** | 🆕 Powerful Logic | Advanced MoE model (Q4_K_M only for 8GB VRAM) |
| **Phi-3.5 Mini** | Fast Responses | Microsoft model, uses minimal VRAM |
| **Llava 7B** | Image Recognition | 👁️ Basic photo analysis, descriptions |
| **MiniCPM-V** | Detailed Vision | 👁️ Incredible detail and OCR for images |
| **Moondream 2** | Very Light Vision | 👁️ Fast photo reading with minimal VRAM cost |
| **Nomic Embed Text** | Embeddings | 📑 Essential for document search (RAG) |
| **DeepSeek Coder 16B**| Complex Coding | Slower than Qwen 2.5 (partially in system RAM) |
| **Mistral 7B** | Alternative Chat | Classic lightweight base model |

### 📊 Gemma 4 VRAM Requirements Detail

| Gemma 4 Variant | VRAM Needed (Q4_K_M) | 8GB Compatible? |
| :--- | :--- | :--- |
| **E2B** | ~1 GB + overhead | ✅ Yes, very comfortable |
| **E4B** | ~2.4 GB + overhead | ✅ Yes, runs great |
| **26B MoE A4B** | ~7 GB + overhead | ⚠️ Yes, but tight (Q4_K_M only) |
| **31B Dense** | ~11 GB + overhead | ❌ No, needs 16GB+ |

**Note:** Gemma 4 26B MoE uses only ~4B active parameters per token (Mixture of Experts), making it faster than dense models of similar size.

---

## 🔧 Setup for VS Code (Kilo/Continue)
To connect a local agent, use the following details:
- **Provider:** Ollama
- **Server URL:** `http://localhost:11434`
- **Model:** Name of the selected model (e.g. `qwen2.5-coder:7b`)

*Note: The configuration has `OLLAMA_ORIGINS=*` enabled, which allows extensions to access the API without being blocked.*

---

## 📝 Operating Notes
1.  **First Launch:** The first user registered in Open WebUI becomes the administrator.
2.  **Resource Consumption:** Before launching heavy games, it's recommended to run `./stop.sh` to free video memory.
3.  **Updates:** To update services to their latest versions:

    ```bash
    docker compose pull
    ./manage.sh
    ```

---
**Built for RTX 5060.** Enjoy!
