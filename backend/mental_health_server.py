import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import requests
import torch
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from peft import PeftModel
from pydantic import BaseModel, Field
from transformers import AutoModelForCausalLM, AutoTokenizer

app = FastAPI(title="MindReset Mental Health Chat Backend")


def _load_local_env() -> None:
    env_path = Path(__file__).with_name(".env")
    if not env_path.exists():
        return

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_local_env()

_cors_origins = [
    origin.strip()
    for origin in os.environ.get(
        "MENTAL_HEALTH_CORS_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:3000,http://localhost:5000,http://127.0.0.1:5000",
    ).split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins if _cors_origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


DEFAULT_SYSTEM_PROMPT = (
    "You are a calm, practical study support assistant inside a mental wellness app for students. "
    "Be warm, grounded, and concise. You are not a replacement for a licensed clinician. "
    "Keep replies short, clear, and non-overwhelming. Use plain text only. "
    "Return 1 to 2 short lines. First validate simply. Then ask one clear next-step question or give one tiny 10-minute action. "
    "When the user mentions a big task, studying, exams, procrastination, or feeling stuck, automatically break it into exactly 3 tiny ADHD-friendly steps. "
    "Use this format: Let's break it down: Step 1: ... Step 2: ... Step 3: ... Keep each step short and doable. "
    "Do not use long lists, paragraphs, or multiple suggestions."
)

MODEL_REGISTRY = {
    "qwen_mental": {
        "model_id": "Qwen/Qwen2.5-0.5B-Instruct",
        "tokenizer_id": "Qwen/Qwen2.5-0.5B-Instruct",
        "kind": "merged",
        "enabled_env": "ENABLE_QWEN_MENTAL_HEALTH",
    },
    "kaneki_adapter": {
        "model_id": "Kaneki24/llama3-1b-mental-health-chatbot",
        "tokenizer_id": "meta-llama/Llama-3.2-1B-Instruct",
        "base_model_id": "meta-llama/Llama-3.2-1B-Instruct",
        "kind": "adapter",
        "enabled_env": "ENABLE_KANEKI_ADAPTER",
    },
}


class ChatTurn(BaseModel):
    role: str
    text: str


class EnsembleRequest(BaseModel):
    message: str
    history: list[ChatTurn] = Field(default_factory=list)
    system_prompt: str = DEFAULT_SYSTEM_PROMPT
    include_gemini: bool = True
    max_new_tokens: int = 256


class ProviderTestRequest(BaseModel):
    provider: str
    message: str
    history: list[ChatTurn] = Field(default_factory=list)
    system_prompt: str = DEFAULT_SYSTEM_PROMPT
    max_new_tokens: int = 256


class ProviderReply(BaseModel):
    name: str
    detail: str
    state: str
    text: str | None = None


class EnsembleResponse(BaseModel):
    replies: list[ProviderReply]
    crisis_detected: bool = False


@dataclass
class LoadedModel:
    model_id: str
    tokenizer: Any
    model: Any


_model_cache: dict[str, LoadedModel] = {}
_provider_status: dict[str, dict[str, Any]] = {
    "qwen_mental": {
        "name": MODEL_REGISTRY["qwen_mental"]["model_id"],
        "loaded": False,
        "detail": "Waiting to load",
    },
    "kaneki_adapter": {
        "name": MODEL_REGISTRY["kaneki_adapter"]["model_id"],
        "loaded": False,
        "detail": "Waiting to load",
    },
    "gemini": {
        "name": "Gemini",
        "loaded": False,
        "detail": "No API key configured",
    },
}
_gemini_api_key = os.environ.get("GEMINI_API_KEY", "").strip()
_gemini_model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash").strip()
_default_max_new_tokens = int(os.environ.get("GEMINI_MAX_OUTPUT_TOKENS", "96"))
_hf_token = os.environ.get("HF_TOKEN", "").strip()
_preload_models = os.environ.get("PRELOAD_HF_MODELS", "false").strip().lower() in {
    "1",
    "true",
    "yes",
    "on",
}

if _gemini_api_key:
    _provider_status["gemini"] = {
        "name": "Gemini",
        "loaded": True,
        "detail": f"Configured for {_gemini_model}",
    }


def _env_flag(name: str, default: bool = True) -> bool:
    raw = os.environ.get(name, str(default)).strip().lower()
    return raw in {"1", "true", "yes", "on"}


def _device() -> torch.device:
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")


def _dtype() -> torch.dtype:
    return torch.float16 if torch.cuda.is_available() else torch.float32


def _model_load_kwargs() -> dict[str, Any]:
    kwargs: dict[str, Any] = dict(_auth_kwargs())
    if torch.cuda.is_available():
        kwargs["device_map"] = "auto"
        kwargs["dtype"] = _dtype()
    return kwargs


def _auth_kwargs() -> dict[str, Any]:
    return {"token": _hf_token} if _hf_token else {}


def _build_prompt(system_prompt: str, history: list[ChatTurn], message: str) -> str:
    prompt_parts = [system_prompt.strip(), "", "Conversation:"]
    for turn in history[-6:]:
        speaker = "User" if turn.role == "user" else "Assistant"
        prompt_parts.append(f"{speaker}: {turn.text.strip()}")
    prompt_parts.append(f"User: {message.strip()}")
    prompt_parts.append("Assistant:")
    return "\n".join(prompt_parts)


def _strip_prompt(prompt: str, generated: str) -> str:
    cleaned = generated.strip()
    if cleaned.startswith(prompt):
        cleaned = cleaned[len(prompt):].strip()
    if "Assistant:" in cleaned:
        cleaned = cleaned.split("Assistant:", 1)[-1].strip()
    return cleaned


def _ensure_provider_enabled(model_key: str) -> bool:
    config = MODEL_REGISTRY[model_key]
    enabled = _env_flag(config["enabled_env"], True)
    if not enabled:
        _provider_status[model_key] = {
            "name": config["model_id"],
            "loaded": False,
            "detail": "Disabled by backend environment",
        }
    return enabled


def _load_model(model_key: str) -> LoadedModel:
    if model_key in _model_cache:
        return _model_cache[model_key]

    config = MODEL_REGISTRY[model_key]
    model_id = config["model_id"]

    try:
        if config["kind"] == "merged":
            tokenizer = AutoTokenizer.from_pretrained(
                config["tokenizer_id"],
                **_auth_kwargs(),
            )
            if tokenizer.pad_token is None:
                tokenizer.pad_token = tokenizer.eos_token
            model = AutoModelForCausalLM.from_pretrained(
                model_id,
                **_model_load_kwargs(),
            )
        else:
            base_model_id = config["base_model_id"]
            tokenizer = AutoTokenizer.from_pretrained(
                config["tokenizer_id"],
                **_auth_kwargs(),
            )
            if tokenizer.pad_token is None:
                tokenizer.pad_token = tokenizer.eos_token
            base_model = AutoModelForCausalLM.from_pretrained(
                base_model_id,
                **_model_load_kwargs(),
            )
            model = PeftModel.from_pretrained(
                base_model,
                model_id,
                **_auth_kwargs(),
            )

        if not torch.cuda.is_available():
            model.to(_device())
        model.eval()

        loaded = LoadedModel(
            model_id=model_id,
            tokenizer=tokenizer,
            model=model,
        )
        _model_cache[model_key] = loaded
        _provider_status[model_key] = {
            "name": model_id,
            "loaded": True,
            "detail": f"Loaded on {_device().type}",
        }
        return loaded
    except Exception as exc:  # noqa: BLE001
        _provider_status[model_key] = {
            "name": model_id,
            "loaded": False,
            "detail": f"Load failed: {type(exc).__name__}: {exc}",
        }
        raise


def _generate_hf_reply(
    model_key: str,
    system_prompt: str,
    history: list[ChatTurn],
    message: str,
    max_new_tokens: int,
) -> ProviderReply:
    if not _ensure_provider_enabled(model_key):
        return ProviderReply(
            name=MODEL_REGISTRY[model_key]["model_id"],
            detail="Disabled by backend environment",
            state="inactive",
        )

    try:
        loaded = _load_model(model_key)
        prompt = _build_prompt(system_prompt, history, message)
        inputs = loaded.tokenizer(prompt, return_tensors="pt").to(_device())

        with torch.no_grad():
            if model_key == "qwen_mental":
                output = loaded.model.generate(
                    inputs.input_ids,
                    attention_mask=inputs.get("attention_mask"),
                    max_new_tokens=min(max_new_tokens, _default_max_new_tokens),
                    temperature=0.7,
                    top_p=0.9,
                    do_sample=True,
                    pad_token_id=loaded.tokenizer.eos_token_id,
                )
            else:
                output = loaded.model.generate(
                    **inputs,
                    max_new_tokens=min(max_new_tokens, _default_max_new_tokens),
                    repetition_penalty=1.08,
                    do_sample=False,
                    pad_token_id=loaded.tokenizer.eos_token_id,
                )

        decoded = loaded.tokenizer.decode(output[0], skip_special_tokens=True)
        text = _strip_prompt(prompt, decoded)
        if not text:
            return ProviderReply(
                name=loaded.model_id,
                detail=f"{_device().type} ready",
                state="inactive",
            )

        return ProviderReply(
            name=loaded.model_id,
            detail=f"{_device().type} live",
            state="live",
            text=text,
        )
    except Exception as exc:  # noqa: BLE001
        return ProviderReply(
            name=MODEL_REGISTRY[model_key]["model_id"],
            detail=f"Unavailable: {type(exc).__name__}: {exc}",
            state="inactive",
        )


def _to_gemini_contents(history: list[ChatTurn], message: str) -> list[dict[str, Any]]:
    contents: list[dict[str, Any]] = []
    for turn in history[-6:]:
        contents.append(
            {
                "role": "user" if turn.role == "user" else "model",
                "parts": [{"text": turn.text}],
            }
        )
    contents.append(
        {
            "role": "user",
            "parts": [{"text": message}],
        }
    )
    return contents


def _generate_gemini_reply(
    system_prompt: str,
    history: list[ChatTurn],
    message: str,
    max_new_tokens: int,
) -> ProviderReply:
    if not _gemini_api_key:
        _provider_status["gemini"] = {
            "name": "Gemini",
            "loaded": False,
            "detail": "No GEMINI_API_KEY found in backend/.env or environment",
        }
        return ProviderReply(
            name="Gemini",
            detail="Add GEMINI_API_KEY on backend",
            state="inactive",
        )

    try:
        response = requests.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/{_gemini_model}:generateContent",
            headers={
                "x-goog-api-key": _gemini_api_key,
                "Content-Type": "application/json",
            },
            json={
                "systemInstruction": {
                    "parts": [{"text": system_prompt}],
                },
                "contents": _to_gemini_contents(history, message),
                "generationConfig": {
                    "temperature": 0.4,
                    "maxOutputTokens": min(max(max_new_tokens, _default_max_new_tokens, 32), 128),
                },
            },
            timeout=12,
        )
        response.raise_for_status()
        payload = response.json()
        candidates = payload.get("candidates") or []
        parts = (((candidates[0] or {}).get("content") or {}).get("parts") or []) if candidates else []
        text = "\n".join(
            part.get("text", "")
            for part in parts
            if isinstance(part, dict) and isinstance(part.get("text"), str)
        ).strip()

        if not text:
            _provider_status["gemini"] = {
                "name": "Gemini",
                "loaded": False,
                "detail": f"{_gemini_model} returned no text",
            }
            return ProviderReply(
                name="Gemini",
                detail=_gemini_model,
                state="inactive",
            )

        _provider_status["gemini"] = {
            "name": "Gemini",
            "loaded": True,
            "detail": f"{_gemini_model} responded successfully",
        }
        return ProviderReply(
            name="Gemini",
            detail=_gemini_model,
            state="live",
            text=text,
        )
    except Exception as exc:  # noqa: BLE001
        _provider_status["gemini"] = {
            "name": "Gemini",
            "loaded": False,
            "detail": f"Request failed: {type(exc).__name__}: {exc}",
        }
        return ProviderReply(
            name="Gemini",
            detail=f"Unavailable: {type(exc).__name__}: {exc}",
            state="inactive",
        )


def _detect_crisis(message: str) -> bool:
    lowered = message.lower()
    crisis_terms = [
        "suicide",
        "kill myself",
        "end my life",
        "self harm",
        "hurt myself",
        "want to die",
    ]
    return any(term in lowered for term in crisis_terms)


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "device": _device().type,
        "cached_models": list(_model_cache.keys()),
        "preload_hf_models": _preload_models,
        "hf_token_configured": bool(_hf_token),
        "gemini_enabled": bool(_gemini_api_key),
        "providers": _provider_status,
    }


@app.on_event("startup")
def preload_models_on_startup() -> None:
    if not _preload_models:
        return

    for model_key in ("qwen_mental", "kaneki_adapter"):
        if not _ensure_provider_enabled(model_key):
            continue
        try:
            _load_model(model_key)
        except Exception:
            continue


@app.post("/chat/ensemble", response_model=EnsembleResponse)
def chat_ensemble(request: EnsembleRequest) -> EnsembleResponse:
    replies: list[ProviderReply] = [
        _generate_hf_reply(
            "qwen_mental",
            request.system_prompt,
            request.history,
            request.message,
            request.max_new_tokens,
        ),
        _generate_hf_reply(
            "kaneki_adapter",
            request.system_prompt,
            request.history,
            request.message,
            request.max_new_tokens,
        ),
    ]

    if request.include_gemini:
        replies.append(
            _generate_gemini_reply(
                request.system_prompt,
                request.history,
                request.message,
                request.max_new_tokens,
            )
        )

    return EnsembleResponse(
        replies=replies,
        crisis_detected=_detect_crisis(request.message),
    )


@app.post("/chat/provider-test", response_model=ProviderReply)
def provider_test(request: ProviderTestRequest) -> ProviderReply:
    if request.provider == "qwen_mental":
        return _generate_hf_reply(
            "qwen_mental",
            request.system_prompt,
            request.history,
            request.message,
            request.max_new_tokens,
        )
    if request.provider == "kaneki_adapter":
        return _generate_hf_reply(
            "kaneki_adapter",
            request.system_prompt,
            request.history,
            request.message,
            request.max_new_tokens,
        )
    if request.provider == "gemini":
        return _generate_gemini_reply(
            request.system_prompt,
            request.history,
            request.message,
            request.max_new_tokens,
        )

    return ProviderReply(
        name=request.provider,
        detail="Unknown provider",
        state="inactive",
    )


if __name__ == "__main__":
    uvicorn.run(
        "mental_health_server:app",
        host=os.environ.get("MENTAL_HEALTH_HOST", "127.0.0.1"),
        port=int(os.environ.get("MENTAL_HEALTH_PORT", "8000")),
        reload=False,
    )
