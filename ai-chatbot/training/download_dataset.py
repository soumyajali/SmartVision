"""
Dataset Downloader & License Auditor for Custom AI Chatbot
Downloads real conversational and reasoning datasets from Hugging Face:
- Databricks Dolly 15K (Apache 2.0)
- OpenAI GSM8K (MIT)
- OpenAssistant OASST1 (Apache 2.0)
- LMSYS Chat-1M (Checks access & reports gated status if unauthenticated)
"""

import os
import sys
import json
import certifi
from typing import Dict, Any

# Ensure SSL certificates are properly configured for macOS Python
os.environ['SSL_CERT_FILE'] = certifi.where()
os.environ['REQUESTS_CA_BUNDLE'] = certifi.where()

# Remove current working directory from sys.path if named 'datasets' to avoid shadowing
sys.path = [p for p in sys.path if p not in ['', '.', os.path.abspath('.')]]
from datasets import load_dataset

DATASETS_CONFIG = {
    "dolly_15k": {
        "hf_id": "databricks/databricks-dolly-15k",
        "split": "train",
        "license": "Apache-2.0",
        "type": "instruction-response",
        "description": "15,000 high-quality human instruction-following records by Databricks employees."
    },
    "gsm8k": {
        "hf_id": "openai/gsm8k",
        "config_name": "main",
        "split": "train",
        "license": "MIT",
        "type": "math-reasoning",
        "description": "Grade school math problems with multi-step chain-of-thought solutions."
    },
    "oasst1": {
        "hf_id": "OpenAssistant/oasst1",
        "split": "train",
        "license": "Apache-2.0",
        "type": "conversation-trees",
        "description": "Crowdsourced human dialogue trees across diverse languages and domains."
    },
    "lmsys_chat_1m": {
        "hf_id": "lmsys/lmsys-chat-1m",
        "split": "train",
        "license": "CC-BY-NC-4.0 (Non-Commercial, Gated)",
        "type": "arena-conversations",
        "description": "1 million real-world conversations with 25 state-of-the-art LLMs."
    }
}

def download_and_audit_datasets(raw_dir: str = "datasets/raw", sample_limit: int = 1000):
    os.makedirs(raw_dir, exist_ok=True)
    manifest = {
        "download_timestamp": None,
        "datasets": {}
    }
    
    print("=" * 70)
    print("AI CHATBOT DATASET ACQUISITION & LICENSE AUDIT")
    print("=" * 70)

    for key, info in DATASETS_CONFIG.items():
        print(f"\n[Dataset: {key.upper()}] ({info['hf_id']})")
        print(f"  License: {info['license']}")
        print(f"  Category: {info['type']}")
        
        target_path = os.path.join(raw_dir, f"{key}_raw.jsonl")
        
        try:
            print("  Connecting to Hugging Face Hub...")
            if "config_name" in info:
                split_query = f"{info['split']}[:{sample_limit}]" if sample_limit else info['split']
                ds = load_dataset(info['hf_id'], info['config_name'], split=split_query)
            else:
                split_query = f"{info['split']}[:{sample_limit}]" if sample_limit else info['split']
                ds = load_dataset(info['hf_id'], split=split_query)

            record_count = len(ds)
            print(f"  Successfully accessed {record_count} records. Columns: {ds.column_names}")
            
            # Save raw dataset to jsonl
            with open(target_path, "w", encoding="utf-8") as f:
                for row in ds:
                    f.write(json.dumps(row, ensure_ascii=False) + "\n")
                    
            manifest["datasets"][key] = {
                "status": "DOWNLOADED",
                "hf_id": info["hf_id"],
                "license": info["license"],
                "records_saved": record_count,
                "local_path": target_path,
                "columns": ds.column_names
            }
            print(f"  Saved locally to: {target_path}")
            
        except Exception as e:
            err_msg = str(e)
            if "gated" in err_msg.lower() or "notfound" in err_msg.lower():
                status = "GATED_OR_REQUIRES_AUTH"
                print(f"  ⚠️ NOTICE: Gated dataset. Access requires authenticated Hugging Face token and terms agreement.")
            else:
                status = "ERROR"
                print(f"  ⚠️ Download failed: {err_msg[:120]}")
                
            manifest["datasets"][key] = {
                "status": status,
                "hf_id": info["hf_id"],
                "license": info["license"],
                "error": err_msg[:200]
            }

    # Save manifest audit file
    manifest_path = os.path.join(raw_dir, "dataset_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        
    print("\n" + "=" * 70)
    print(f"Audit Manifest saved to: {manifest_path}")
    print("=" * 70)
    return manifest

if __name__ == "__main__":
    # If run standalone, download up to 2000 samples per dataset for swift M3 local experimentation
    limit = 2000 if len(sys.argv) < 2 else int(sys.argv[1])
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    raw_output = os.path.join(project_root, "datasets", "raw")
    download_and_audit_datasets(raw_dir=raw_output, sample_limit=limit)
