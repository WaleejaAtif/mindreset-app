import json
import os

import requests


BASE_URL = os.environ.get("MENTAL_HEALTH_BASE_URL", "http://127.0.0.1:8000").rstrip("/")

PAYLOAD = {
    "message": "I feel anxious and cannot focus on studying tonight. Please help me calmly.",
    "history": [],
    "include_gemini": True,
    "max_new_tokens": 180,
}


def main() -> None:
    health = requests.get(f"{BASE_URL}/health", timeout=30)
    health.raise_for_status()
    print("HEALTH")
    print(json.dumps(health.json(), indent=2))

    response = requests.post(
        f"{BASE_URL}/chat/ensemble",
        json=PAYLOAD,
        timeout=180,
    )
    response.raise_for_status()
    print("\nENSEMBLE TEST")
    print(json.dumps(response.json(), indent=2))


if __name__ == "__main__":
    main()
