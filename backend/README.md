# MindReset Chat Backend

This backend uses two Hugging Face mental-health models plus optional Gemini.

## Models

- `help2opensource/Qwen3-4B-Instruct-2507_mental_health`
- `Kaneki24/llama3-1b-mental-health-chatbot`
- Optional Gemini via `GEMINI_API_KEY`

Important:

- `Kaneki24/llama3-1b-mental-health-chatbot` is a PEFT adapter
- it depends on `meta-llama/Llama-3.2-1B-Instruct`
- you may need to accept the Meta model license on Hugging Face first
- using `HF_TOKEN` is strongly recommended

## Setup

```powershell
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

## Configure Gemini

Put your Gemini key in:

```text
backend/.env
```

Example:

```env
GEMINI_API_KEY=your-real-gemini-key
GEMINI_MODEL=gemini-2.5-flash
GEMINI_MAX_OUTPUT_TOKENS=96
HF_TOKEN=your-huggingface-read-token
ENABLE_QWEN_MENTAL_HEALTH=true
ENABLE_KANEKI_ADAPTER=true
PRELOAD_HF_MODELS=false
```

## Run

```powershell
python mental_health_server.py
```

The backend starts on `http://127.0.0.1:8000`.

## Verify Providers

Open:

```text
http://127.0.0.1:8000/health
```

You should see a `providers` section that reports whether:

- `help2opensource/Qwen3-4B-Instruct-2507_mental_health` loaded
- `Kaneki24/llama3-1b-mental-health-chatbot` loaded
- Gemini is configured and responding

## Test The Ensemble

While the backend is running:

```powershell
python test_ensemble.py
```

This will print:

- backend health
- provider load status
- one combined ensemble test call

## Test Providers Individually

You can also test one provider at a time:

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8000/chat/provider-test' `
  -Method Post `
  -ContentType 'application/json' `
  -Body '{"provider":"gemini","message":"I feel anxious lately. Please help me calmly.","history":[]}'
```

Valid `provider` values:

- `qwen_mental`
- `kaneki_adapter`
- `gemini`

For Android emulator builds, run Flutter with:

```powershell
flutter run --dart-define=SMART_CHAT_BACKEND_URL=http://10.0.2.2:8000
```

For desktop or web on the same machine, this works:

```powershell
flutter run --dart-define=SMART_CHAT_BACKEND_URL=http://127.0.0.1:8000
```
