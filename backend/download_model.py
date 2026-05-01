from transformers import AutoModelForCausalLM, AutoTokenizer
import time

print("Downloading and caching Qwen 0.5B model locally so your backend starts instantly...")
start = time.time()
model_id = "Qwen/Qwen2.5-0.5B-Instruct"

tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(model_id)

elapsed = time.time() - start
print(f"Success! Model completely downloaded and cached in {elapsed:.1f} seconds.")
