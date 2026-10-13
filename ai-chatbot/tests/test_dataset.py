"""
Unit tests for Dataset Downloader and Preprocessor
"""

import os
import json
import pytest

def test_processed_dataset_exists():
    train_path = os.path.join(os.path.dirname(__file__), "..", "datasets", "processed", "train.jsonl")
    val_path = os.path.join(os.path.dirname(__file__), "..", "datasets", "processed", "val.jsonl")
    
    assert os.path.exists(train_path), "train.jsonl does not exist"
    assert os.path.exists(val_path), "val.jsonl does not exist"

def test_chatml_formatting():
    train_path = os.path.join(os.path.dirname(__file__), "..", "datasets", "processed", "train.jsonl")
    with open(train_path, "r", encoding="utf-8") as f:
        first_line = f.readline()
        data = json.loads(first_line)
    
    assert "messages" in data, "Record missing 'messages' key"
    messages = data["messages"]
    assert len(messages) >= 2, "Conversation must have at least user and assistant"
    
    roles = [m["role"] for m in messages]
    assert "user" in roles, "Missing user role"
    assert "assistant" in roles, "Missing assistant role"
    for m in messages:
        assert isinstance(m["content"], str), "Message content must be string"
        assert len(m["content"].strip()) > 0, "Message content cannot be blank"

def test_manifest_audit():
    manifest_path = os.path.join(os.path.dirname(__file__), "..", "datasets", "raw", "dataset_manifest.json")
    assert os.path.exists(manifest_path), "dataset_manifest.json does not exist"
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)
    
    assert "datasets" in manifest
    # Check that datasets are truthfully audited
    dataset_ids = [d["hf_id"] for d in manifest["datasets"].values()]
    assert "OpenAssistant/oasst1" in dataset_ids
    assert "databricks/databricks-dolly-15k" in dataset_ids
    assert "openai/gsm8k" in dataset_ids
    assert "lmsys/lmsys-chat-1m" in dataset_ids
