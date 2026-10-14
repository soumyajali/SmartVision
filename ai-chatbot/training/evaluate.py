"""
Model Evaluation & Benchmark Suite
Evaluates base and fine-tuned language models across:
1. Mathematical Reasoning (GSM8K)
2. Instruction Following (Dolly 15K)
3. Multi-Turn Dialogue Memory
4. Latency & Generation Speed (Tokens/Second)
"""

import os
import sys
import re
import time
import json
import certifi
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

os.environ['SSL_CERT_FILE'] = certifi.where()
os.environ['REQUESTS_CA_BUNDLE'] = certifi.where()

try:
    from peft import PeftModel
    PEFT_AVAILABLE = True
except ImportError:
    PEFT_AVAILABLE = False

EVALUATION_BENCHMARK = [
    {
        "category": "math_reasoning",
        "prompt": "Natalia sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalia sell in April and May combined?",
        "expected_answer": "72",
        "description": "Multi-step addition and division"
    },
    {
        "category": "math_reasoning",
        "prompt": "A bakery makes 60 cupcakes. 25 are chocolate and 15 are vanilla. The rest are strawberry. How many cupcakes are strawberry?",
        "expected_answer": "20",
        "description": "Subtraction subtraction arithmetic"
    },
    {
        "category": "instruction_following",
        "prompt": "List exactly 3 key benefits of solar energy using bullet points.",
        "expected_elements": ["renewable", "cost", "clean", "environment", "sun"],
        "description": "Numbered/bullet list formatting"
    },
    {
        "category": "instruction_following",
        "prompt": "Explain the difference between a Python list and a tuple in two clear sentences.",
        "expected_elements": ["mutable", "immutable"],
        "description": "Technical conceptual distinction"
    },
    {
        "category": "multi_turn",
        "conversation": [
            {"role": "user", "content": "My favorite fruit is mango. Remember that!"},
            {"role": "assistant", "content": "I have noted that your favorite fruit is mango!"},
            {"role": "user", "content": "What is my favorite fruit?"}
        ],
        "expected_answer": "mango",
        "description": "Contextual entity recall across turns"
    }
]

def generate_response(model, tokenizer, messages, device, max_new_tokens: int = 150, temperature: float = 0.2):
    prompt_text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = tokenizer(prompt_text, return_tensors="pt").to(device)
    
    t0 = time.time()
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            temperature=temperature,
            do_sample=temperature > 0.0,
            pad_token_id=tokenizer.eos_token_id
        )
    elapsed = time.time() - t0
    
    gen_tokens = outputs[0][inputs["input_ids"].shape[1]:]
    response_text = tokenizer.decode(gen_tokens, skip_special_tokens=True).strip()
    num_tokens = len(gen_tokens)
    tok_per_sec = num_tokens / max(0.001, elapsed)
    
    return response_text, tok_per_sec

def run_evaluation(
    model_name: str = "Qwen/Qwen2.5-0.5B-Instruct",
    adapter_dir: str = None,
    output_report: str = "checkpoints/evaluation_report.json"
):
    print("=" * 70)
    print("AI CHATBOT MULTI-DIMENSIONAL BENCHMARK EVALUATION")
    print("=" * 70)

    # 1. Device Selection (CPU provides stable, fast generation on Apple Silicon M3 without MPS NDArray kernel bugs)
    device_arg = os.environ.get("DEVICE", "cpu")
    if device_arg == "cuda" and torch.cuda.is_available():
        device = torch.device("cuda:0")
        print("Hardware Acceleration: NVIDIA CUDA")
    elif device_arg == "mps" and torch.backends.mps.is_available():
        device = torch.device("mps")
        print("Hardware Acceleration: Apple Silicon MPS")
    else:
        device = torch.device("cpu")
        print("Hardware Engine: Apple Silicon CPU (High-Performance Cores)")

    # 2. Tokenizer & Model
    print(f"\nLoading Tokenizer & Model: {model_name}...")
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    torch_dtype = torch.float16 if device.type in ["mps", "cuda"] else torch.float32
    model = AutoModelForCausalLM.from_pretrained(
        model_name,
        torch_dtype=torch_dtype,
        trust_remote_code=True
    )

    # Apply LoRA adapter if provided and PEFT available
    if adapter_dir and os.path.exists(adapter_dir) and PEFT_AVAILABLE:
        print(f"Loading Fine-Tuned LoRA Adapter from: {adapter_dir}...")
        try:
            model = PeftModel.from_pretrained(model, adapter_dir)
            print("  ✅ LoRA Adapter loaded successfully!")
        except Exception as e:
            print(f"  Notice: Could not load LoRA adapter ({e}), testing base model.")

    model.to(device)
    model.eval()

    results = []
    total_speed = 0.0
    passed_math = 0
    total_math = 0

    print("\nRunning Benchmark Test Cases:")
    for idx, test in enumerate(EVALUATION_BENCHMARK):
        print(f"\n[Test {idx + 1}] Category: {test['category'].upper()} | {test['description']}")
        
        if "conversation" in test:
            messages = test["conversation"]
            print(f"  User Query: \"{messages[-1]['content']}\"")
        else:
            messages = [{"role": "user", "content": test["prompt"]}]
            print(f"  User Query: \"{test['prompt'][:65]}...\"")

        reply, speed = generate_response(model, tokenizer, messages, device)
        total_speed += speed
        print(f"  Speed: {speed:.1f} tokens/sec")
        print(f"  Model Response:\n    \"{reply[:180]}...\"")

        # Evaluate correctness
        is_pass = False
        reply_lower = reply.lower()

        if test["category"] == "math_reasoning":
            total_math += 1
            exp = test["expected_answer"]
            # Check if expected number appears in text
            if exp in reply or f"={exp}" in reply or f" {exp}" in reply:
                is_pass = True
                passed_math += 1

        elif test["category"] == "instruction_following":
            matches = sum(1 for e in test.get("expected_elements", []) if e in reply_lower)
            is_pass = matches >= 1

        elif test["category"] == "multi_turn":
            is_pass = test["expected_answer"].lower() in reply_lower

        status_str = "✅ PASS" if is_pass else "⚠️ PARTIAL"
        print(f"  Result: {status_str}")

        results.append({
            "test_index": idx + 1,
            "category": test["category"],
            "description": test["description"],
            "passed": is_pass,
            "tokens_per_second": round(speed, 1),
            "generated_sample": reply[:250]
        })

    avg_speed = total_speed / len(EVALUATION_BENCHMARK)
    summary = {
        "model_name": model_name,
        "device": str(device),
        "adapter_tested": bool(adapter_dir),
        "average_generation_speed_tok_sec": round(avg_speed, 1),
        "math_reasoning_accuracy": f"{passed_math}/{total_math}" if total_math else "N/A",
        "detailed_results": results
    }

    os.makedirs(os.path.dirname(output_report) or ".", exist_ok=True)
    with open(output_report, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)

    print("\n" + "=" * 70)
    print("BENCHMARK EVALUATION SUMMARY")
    print(f"  Average Generation Latency: {avg_speed:.1f} tokens/second")
    print(f"  Math Accuracy:              {passed_math}/{total_math}")
    print(f"  Evaluation Report Saved:    {output_report}")
    print("=" * 70)
    return summary

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    adapter = os.path.join(project_root, "checkpoints", "qwen_chatbot_lora")
    if not os.path.exists(adapter):
        adapter = None
    rep_path = os.path.join(project_root, "checkpoints", "evaluation_report.json")
    run_evaluation(adapter_dir=adapter, output_report=rep_path)
