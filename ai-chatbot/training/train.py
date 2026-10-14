"""
Supervised Fine-Tuning (SFT) with LoRA for Pretrained Language Models
Hardware Target: Apple Silicon M3 (MPS) and CUDA / CPU
Model: Qwen2.5-0.5B-Instruct (or configurable)
Parameter-Efficient Fine-Tuning: Low-Rank Adaptation (LoRA) via PEFT
"""

import os
import sys
import json
import time
import math
import argparse
import certifi
import torch
from torch.utils.data import Dataset, DataLoader
from torch.optim import AdamW
from transformers import AutoTokenizer, AutoModelForCausalLM, get_cosine_schedule_with_warmup
from peft import LoraConfig, get_peft_model, TaskType

# Set SSL certificates
os.environ['SSL_CERT_FILE'] = certifi.where()
os.environ['REQUESTS_CA_BUNDLE'] = certifi.where()

class ChatMLDataset(Dataset):
    """Loads ChatML conversational records and applies model chat template."""
    def __init__(self, jsonl_path: str, tokenizer, max_seq_len: int = 512, limit: int = None):
        self.examples = []
        if not os.path.exists(jsonl_path):
            raise FileNotFoundError(f"Missing dataset at {jsonl_path}")

        print(f"Loading and tokenizing {jsonl_path}...")
        with open(jsonl_path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f):
                if limit and idx >= limit:
                    break
                if not line.strip():
                    continue
                record = json.loads(line)
                messages = record.get("messages", [])
                if not messages:
                    continue
                
                # Apply chat template
                try:
                    formatted_text = tokenizer.apply_chat_template(
                        messages, 
                        tokenize=False, 
                        add_generation_prompt=False
                    )
                    enc = tokenizer(
                        formatted_text,
                        truncation=True,
                        max_length=max_seq_len,
                        padding=False,
                        return_tensors=None
                    )
                    input_ids = enc["input_ids"]
                    if len(input_ids) > 10:
                        self.examples.append(input_ids)
                except Exception:
                    continue
        print(f"  Loaded {len(self.examples)} tokenized sequences (max_len={max_seq_len}).")

    def __len__(self):
        return len(self.examples)

    def __getitem__(self, idx):
        return self.examples[idx]

def collate_fn(batch, pad_token_id: int):
    max_len = max(len(x) for x in batch)
    input_ids = []
    labels = []
    attention_mask = []
    
    for x in batch:
        pad_len = max_len - len(x)
        ids = x + [pad_token_id] * pad_len
        # For standard causal LM loss, predict next token; mask padding with -100
        lbl = x + [-100] * pad_len
        mask = [1] * len(x) + [0] * pad_len
        
        input_ids.append(ids)
        labels.append(lbl)
        attention_mask.append(mask)
        
    return {
        "input_ids": torch.tensor(input_ids, dtype=torch.long),
        "labels": torch.tensor(labels, dtype=torch.long),
        "attention_mask": torch.tensor(attention_mask, dtype=torch.long)
    }

def train_model(
    model_name: str = "Qwen/Qwen2.5-0.5B-Instruct",
    train_path: str = "datasets/processed/train.jsonl",
    val_path: str = "datasets/processed/val.jsonl",
    output_dir: str = "checkpoints/qwen_chatbot_lora",
    epochs: int = 1,
    batch_size: int = 1,
    grad_accum_steps: int = 4,
    lr: float = 2e-4,
    lora_r: int = 8,
    lora_alpha: int = 16,
    max_seq_len: int = 256,
    max_steps: int = 10,
    train_limit: int = 250,
    val_limit: int = 30
):
    print("=" * 70, flush=True)
    print("STARTING SUPERVISED FINE-TUNING (LoRA / PEFT)", flush=True)
    print("=" * 70, flush=True)
    
    # Set MPS memory watermark ratio if on Apple Silicon
    os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"

    # 1. Device Selection (Apple Silicon MPS -> CUDA -> CPU)
    if torch.backends.mps.is_available():
        device = torch.device("mps")
        print(f"🚀 Acceleration Engine: Apple Silicon Metal Performance Shaders (MPS:0)", flush=True)
    elif torch.cuda.is_available():
        device = torch.device("cuda:0")
        print(f"🚀 Acceleration Engine: NVIDIA CUDA ({torch.cuda.get_device_name(0)})", flush=True)
    else:
        device = torch.device("cpu")
        print("⚠️ Acceleration Engine: CPU", flush=True)

    # 2. Tokenizer
    print(f"\n1. Loading Tokenizer: {model_name}...", flush=True)
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    pad_id = tokenizer.pad_token_id

    # 3. Base Model
    print(f"2. Loading Base Causal LM: {model_name}...", flush=True)
    torch_dtype = torch.float16 if (device.type in ["mps", "cuda"]) else torch.float32
    base_model = AutoModelForCausalLM.from_pretrained(
        model_name,
        dtype=torch_dtype,
        trust_remote_code=True
    )
    
    # Memory optimization: enable gradient checkpointing for Apple Silicon
    try:
        base_model.gradient_checkpointing_enable()
        print("💡 Gradient checkpointing enabled to minimize Apple Silicon VRAM footprint.", flush=True)
    except Exception as e:
        print(f"Gradient checkpointing skipped: {e}", flush=True)

    base_model.to(device)

    # 4. LoRA Configuration
    print("3. Applying LoRA (Low-Rank Adaptation)...", flush=True)
    peft_config = LoraConfig(
        task_type=TaskType.CAUSAL_LM,
        r=lora_r,
        lora_alpha=lora_alpha,
        lora_dropout=0.05,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
        bias="none"
    )
    model = get_peft_model(base_model, peft_config)
    model.print_trainable_parameters()

    # 5. Datasets & Loaders
    print("4. Preparing Datasets...", flush=True)
    train_dataset = ChatMLDataset(train_path, tokenizer, max_seq_len=max_seq_len, limit=train_limit)
    val_dataset = ChatMLDataset(val_path, tokenizer, max_seq_len=max_seq_len, limit=val_limit)

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        collate_fn=lambda b: collate_fn(b, pad_id)
    )
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        collate_fn=lambda b: collate_fn(b, pad_id)
    )

    # 6. Optimizer & Schedule
    optimizer = AdamW(model.parameters(), lr=lr, weight_decay=0.01)
    total_training_steps = min(max_steps, len(train_loader) * epochs // grad_accum_steps)
    scheduler = get_cosine_schedule_with_warmup(
        optimizer,
        num_warmup_steps=max(1, int(total_training_steps * 0.1)),
        num_training_steps=total_training_steps
    )

    # 7. Training Loop
    print(f"\n5. Beginning Fine-Tuning ({total_training_steps} optimization steps)...", flush=True)
    model.train()
    step = 0
    running_loss = 0.0
    start_time = time.time()
    log_history = []

    for epoch in range(epochs):
        print(f"\n--- Epoch {epoch + 1}/{epochs} ---", flush=True)
        optimizer.zero_grad()
        
        for batch_idx, batch in enumerate(train_loader):
            input_ids = batch["input_ids"].to(device)
            labels = batch["labels"].to(device)
            attention_mask = batch["attention_mask"].to(device)

            outputs = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
            loss = outputs.loss / grad_accum_steps
            loss.backward()
            running_loss += loss.item() * grad_accum_steps

            if (batch_idx + 1) % grad_accum_steps == 0 or (batch_idx + 1) == len(train_loader):
                torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
                optimizer.step()
                scheduler.step()
                optimizer.zero_grad()
                step += 1

                # Clean MPS cache after each step
                if device.type == "mps":
                    torch.mps.empty_cache()

                avg_loss = running_loss / grad_accum_steps
                ppl = math.exp(min(avg_loss, 20.0))
                elapsed = time.time() - start_time
                lr_curr = scheduler.get_last_lr()[0]

                log_entry = {
                    "step": step,
                    "train_loss": round(avg_loss, 4),
                    "perplexity": round(ppl, 2),
                    "lr": lr_curr,
                    "elapsed_sec": round(elapsed, 1)
                }
                log_history.append(log_entry)
                print(f"  Step {step:02d}/{total_training_steps:02d} | Loss: {avg_loss:.4f} | Perplexity: {ppl:.2f} | LR: {lr_curr:.2e} | Time: {elapsed:.1f}s", flush=True)
                running_loss = 0.0

                if step >= total_training_steps:
                    break

        if step >= total_training_steps:
            break

    # 8. Validation Evaluation
    print("\n6. Running Validation Evaluation...")
    model.eval()
    val_loss_total = 0.0
    val_batches = 0

    with torch.no_grad():
        for batch in val_loader:
            input_ids = batch["input_ids"].to(device)
            labels = batch["labels"].to(device)
            attention_mask = batch["attention_mask"].to(device)
            outputs = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
            val_loss_total += outputs.loss.item()
            val_batches += 1

    avg_val_loss = val_loss_total / max(1, val_batches)
    val_ppl = math.exp(min(avg_val_loss, 20.0))
    print(f"  Validation Loss: {avg_val_loss:.4f} | Validation Perplexity: {val_ppl:.2f}")

    # 9. Save Checkpoint & Metadata
    print(f"\n7. Saving Checkpoint to: {output_dir}...")
    os.makedirs(output_dir, exist_ok=True)
    model.save_pretrained(output_dir)
    tokenizer.save_pretrained(output_dir)

    metrics_meta = {
        "base_model": model_name,
        "device": str(device),
        "steps_trained": step,
        "final_train_loss": log_history[-1]["train_loss"] if log_history else None,
        "val_loss": round(avg_val_loss, 4),
        "val_perplexity": round(val_ppl, 2),
        "lora_r": lora_r,
        "lora_alpha": lora_alpha,
        "training_history": log_history
    }
    with open(os.path.join(output_dir, "training_metrics.json"), "w", encoding="utf-8") as f:
        json.dump(metrics_meta, f, indent=2)

    print("=" * 70)
    print(f"✅ SFT LoRA TRAINING COMPLETE! Adapter saved to {output_dir}")
    print("=" * 70)
    return metrics_meta

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fine-tune local language model with LoRA")
    parser.add_argument("--model", type=str, default="Qwen/Qwen2.5-0.5B-Instruct")
    parser.add_argument("--steps", type=int, default=25, help="Number of optimization steps")
    parser.add_argument("--lr", type=float, default=2e-4)
    parser.add_argument("--output_dir", type=str, default="checkpoints/qwen_chatbot_lora")
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    tr_path = os.path.join(project_root, "datasets", "processed", "train.jsonl")
    vl_path = os.path.join(project_root, "datasets", "processed", "val.jsonl")
    out_path = os.path.join(project_root, args.output_dir)

    train_model(
        model_name=args.model,
        train_path=tr_path,
        val_path=vl_path,
        output_dir=out_path,
        max_steps=args.steps,
        lr=args.lr
    )
