"""
Unit tests for FastAPI endpoints (health, sessions, rag, and chat)
"""

import os
import sys
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from backend.app.main import app

client = TestClient(app)

def test_health_check():
    res = client.get("/api/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert "model_engine" in data
    assert "rag_status" in data

def test_sessions_lifecycle():
    # 1. Create
    res = client.post("/api/sessions", json={"title": "Test Chat", "system_prompt": "You are helpful."})
    assert res.status_code == 200
    created = res.json()
    session_id = created["session_id"]
    assert created["title"] == "Test Chat"
    
    # 2. Get
    res_get = client.get(f"/api/sessions/{session_id}")
    assert res_get.status_code == 200
    assert res_get.json()["session_id"] == session_id
    
    # 3. List
    res_list = client.get("/api/sessions")
    assert res_list.status_code == 200
    assert any(s["session_id"] == session_id for s in res_list.json()["sessions"])
    
    # 4. Delete
    res_del = client.delete(f"/api/sessions/{session_id}")
    assert res_del.status_code == 200
    assert res_del.json()["status"] == "success"

def test_rag_query_endpoint():
    res = client.post("/api/rag/query", json={"query": "test query", "top_k": 3})
    assert res.status_code == 200
    data = res.json()
    assert "matches" in data
