import os
import requests

HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    raise RuntimeError("Set HF_TOKEN before running this test.")
headers = {"Authorization": f"Bearer {HF_TOKEN}"}
url = "https://api-inference.huggingface.co/models/help2opensource/Qwen3-4B-Instruct-2507_mental_health"
res = requests.post(url, headers=headers, json={"inputs": "I feel anxious."})
print(res.status_code)
print(res.text)
