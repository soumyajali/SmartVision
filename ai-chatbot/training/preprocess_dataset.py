"""
Dataset Preprocessor & ChatML Formatter
Cleans, filters, deduplicates, and standardizes multi-source conversational datasets:
- Databricks Dolly 15K
- OpenAI GSM8K
- OpenAssistant OASST1
Outputs:
- datasets/processed/train.jsonl (90% split)
- datasets/processed/val.jsonl (10% split)
- datasets/processed/preprocessing_report.json
"""

import os
import sys
import json
import hashlib
import random
from typing import List, Dict, Any, Tuple

DEFAULT_SYSTEM_PROMPT = (
    "You are an intelligent, articulate, and honest AI assistant. "
    "Provide clear, accurate, and helpful answers with step-by-step reasoning where appropriate."
)

def clean_text(text: str) -> str:
    if not text:
        return ""
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.strip()

def process_dolly_record(row: Dict[str, Any]) -> List[Dict[str, str]]:
    instruction = clean_text(row.get("instruction", ""))
    context = clean_text(row.get("context", ""))
    response = clean_text(row.get("response", ""))
    
    if not instruction or not response:
        return []
    if len(instruction) < 3 or len(response) < 2:
        return []
        
    user_content = f"{instruction}\n\nContext:\n{context}" if context else instruction
    return [
        {"role": "system", "content": DEFAULT_SYSTEM_PROMPT},
        {"role": "user", "content": user_content},
        {"role": "assistant", "content": response}
    ]

def process_gsm8k_record(row: Dict[str, Any]) -> List[Dict[str, str]]:
    question = clean_text(row.get("question", ""))
    answer = clean_text(row.get("answer", ""))
    
    if not question or not answer:
        return []
    if len(question) < 5 or len(answer) < 2:
        return []
        
    return [
        {"role": "system", "content": "You are a skilled mathematical reasoning assistant. Solve the problem with step-by-step logic and highlight the final answer."},
        {"role": "user", "content": question},
        {"role": "assistant", "content": answer}
    ]

def process_oasst1_trees(raw_path: str) -> List[List[Dict[str, str]]]:
    """Reconstructs conversational branches from OpenAssistant tree nodes."""
    if not os.path.exists(raw_path):
        return []
        
    nodes_by_id = {}
    with open(raw_path, "r", encoding="utf-8") as f:
        for line in f:
            if not line.strip():
                continue
            item = json.loads(line)
            # Filter for English language to ensure uniform instruction quality
            if item.get("lang") == "en":
                nodes_by_id[item["message_id"]] = item

    dialogues = []
    # Identify assistant leaf nodes and trace back to root prompter
    for msg_id, node in nodes_by_id.items():
        if node.get("role") == "assistant" and node.get("text"):
            parent_id = node.get("parent_id")
            if parent_id and parent_id in nodes_by_id:
                parent = nodes_by_id[parent_id]
                if parent.get("role") == "prompter" and parent.get("text"):
                    user_text = clean_text(parent["text"])
                    asst_text = clean_text(node["text"])
                    if len(user_text) >= 4 and len(asst_text) >= 4:
                        dialogues.append([
                            {"role": "system", "content": DEFAULT_SYSTEM_PROMPT},
                            {"role": "user", "content": user_text},
                            {"role": "assistant", "content": asst_text}
                        ])
    return dialogues

def preprocess_all(raw_dir: str = "datasets/raw", processed_dir: str = "datasets/processed", split_ratio: float = 0.90):
    os.makedirs(processed_dir, exist_ok=True)
    all_conversations = []
    stats = {
        "sources": {},
        "duplicates_removed": 0,
        "total_valid_conversations": 0,
        "train_count": 0,
        "val_count": 0
    }
    
    seen_prompts = set()

    # 1. Process Dolly 15K
    dolly_path = os.path.join(raw_dir, "dolly_15k_raw.jsonl")
    if os.path.exists(dolly_path):
        count_dolly = 0
        with open(dolly_path, "r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                conv = process_dolly_record(json.loads(line))
                if conv:
                    h = hashlib.md5(conv[1]["content"].lower().encode("utf-8")).hexdigest()
                    if h not in seen_prompts:
                        seen_prompts.add(h)
                        all_conversations.append(conv)
                        count_dolly += 1
                    else:
                        stats["duplicates_removed"] += 1
        stats["sources"]["dolly_15k"] = count_dolly
        print(f"  Processed Dolly 15K: {count_dolly} valid unique records")

    # 2. Process GSM8K
    gsm8k_path = os.path.join(raw_dir, "gsm8k_raw.jsonl")
    if os.path.exists(gsm8k_path):
        count_gsm = 0
        with open(gsm8k_path, "r", encoding="utf-8") as f:
            for line in f:
                if not line.strip():
                    continue
                conv = process_gsm8k_record(json.loads(line))
                if conv:
                    h = hashlib.md5(conv[1]["content"].lower().encode("utf-8")).hexdigest()
                    if h not in seen_prompts:
                        seen_prompts.add(h)
                        all_conversations.append(conv)
                        count_gsm += 1
                    else:
                        stats["duplicates_removed"] += 1
        stats["sources"]["gsm8k"] = count_gsm
        print(f"  Processed GSM8K: {count_gsm} valid unique records")

    # 3. Process OASST1
    oasst_path = os.path.join(raw_dir, "oasst1_raw.jsonl")
    if os.path.exists(oasst_path):
        oasst_convs = process_oasst1_trees(oasst_path)
        count_oasst = 0
        for conv in oasst_convs:
            h = hashlib.md5(conv[1]["content"].lower().encode("utf-8")).hexdigest()
            if h not in seen_prompts:
                seen_prompts.add(h)
                all_conversations.append(conv)
                count_oasst += 1
            else:
                stats["duplicates_removed"] += 1
        stats["sources"]["oasst1"] = count_oasst
        print(f"  Processed OpenAssistant OASST1: {count_oasst} valid unique records")

    total_count = len(all_conversations)
    stats["total_valid_conversations"] = total_count
    
    # Shuffle with reproducible seed
    random.seed(42)
    random.shuffle(all_conversations)

    # Train / Val Split
    split_idx = int(total_count * split_ratio)
    train_data = all_conversations[:split_idx]
    val_data = all_conversations[split_idx:]

    stats["train_count"] = len(train_data)
    stats["val_count"] = len(val_data)

    # Save to disk
    train_path = os.path.join(processed_dir, "train.jsonl")
    val_path = os.path.join(processed_dir, "val.jsonl")

    with open(train_path, "w", encoding="utf-8") as f:
        for item in train_data:
            f.write(json.dumps({"messages": item}, ensure_ascii=False) + "\n")

    with open(val_path, "w", encoding="utf-8") as f:
        for item in val_data:
            f.write(json.dumps({"messages": item}, ensure_ascii=False) + "\n")

    report_path = os.path.join(processed_dir, "preprocessing_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=2)

    print("\n" + "=" * 70)
    print("PREPROCESSING & SPLIT COMPLETE")
    print(f"  Total Valid Dialogues: {total_count}")
    print(f"  Training Split (90%):   {len(train_data)} records -> {train_path}")
    print(f"  Validation Split (10%): {len(val_data)} records -> {val_path}")
    print(f"  Duplicates Eliminated:  {stats['duplicates_removed']}")
    print(f"  Preprocessing Report:   {report_path}")
    print("=" * 70)
    return stats

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    r_dir = os.path.join(project_root, "datasets", "raw")
    p_dir = os.path.join(project_root, "datasets", "processed")
    preprocess_all(raw_dir=r_dir, processed_dir=p_dir)
