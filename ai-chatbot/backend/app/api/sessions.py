"""
Sessions API Router.
Handles multi-turn conversation persistence, session creation, renaming, and deletion.
"""

import os
import json
import uuid
import time
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from backend.app.config import settings

router = APIRouter(prefix="/sessions", tags=["sessions"])

class MessageModel(BaseModel):
    role: str  # "user" or "assistant" or "system"
    content: str
    timestamp: float = Field(default_factory=time.time)
    metrics: Optional[Dict[str, Any]] = None
    citations: Optional[List[Dict[str, Any]]] = None

class SessionCreate(BaseModel):
    title: Optional[str] = "New Conversation"
    system_prompt: Optional[str] = None

class SessionUpdate(BaseModel):
    title: Optional[str] = None
    system_prompt: Optional[str] = None
    messages: Optional[List[Dict[str, Any]]] = None

def _read_sessions() -> Dict[str, Any]:
    if not os.path.exists(settings.SESSIONS_FILE):
        return {}
    try:
        with open(settings.SESSIONS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def _write_sessions(data: Dict[str, Any]):
    with open(settings.SESSIONS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

@router.get("")
def list_sessions():
    """List all saved chat sessions ordered by last updated."""
    data = _read_sessions()
    sessions = []
    for sid, sinfo in data.items():
        sessions.append({
            "session_id": sid,
            "title": sinfo.get("title", "Untitled Chat"),
            "created_at": sinfo.get("created_at", time.time()),
            "updated_at": sinfo.get("updated_at", time.time()),
            "message_count": len(sinfo.get("messages", []))
        })
    sessions.sort(key=lambda s: s["updated_at"], reverse=True)
    return {"sessions": sessions}

@router.post("")
def create_session(payload: SessionCreate):
    """Create a new conversational session."""
    data = _read_sessions()
    session_id = str(uuid.uuid4())[:8]
    now = time.time()
    data[session_id] = {
        "session_id": session_id,
        "title": payload.title or "New Conversation",
        "system_prompt": payload.system_prompt or settings.DEFAULT_SYSTEM_PROMPT,
        "created_at": now,
        "updated_at": now,
        "messages": []
    }
    _write_sessions(data)
    return data[session_id]

@router.get("/{session_id}")
def get_session(session_id: str):
    """Retrieve full messages and metadata for a specific session."""
    data = _read_sessions()
    if session_id not in data:
        raise HTTPException(status_code=404, detail="Session not found")
    return data[session_id]

@router.patch("/{session_id}")
def update_session(session_id: str, payload: SessionUpdate):
    """Update title, system prompt, or messages for a session."""
    data = _read_sessions()
    if session_id not in data:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session = data[session_id]
    if payload.title is not None:
        session["title"] = payload.title
    if payload.system_prompt is not None:
        session["system_prompt"] = payload.system_prompt
    if payload.messages is not None:
        session["messages"] = payload.messages
    session["updated_at"] = time.time()

    _write_sessions(data)
    return session

@router.delete("/{session_id}")
def delete_session(session_id: str):
    """Delete a conversation session."""
    data = _read_sessions()
    if session_id in data:
        del data[session_id]
        _write_sessions(data)
        return {"status": "success", "deleted_session_id": session_id}
    raise HTTPException(status_code=404, detail="Session not found")

@router.delete("")
def clear_all_sessions():
    """Clear all stored conversations."""
    _write_sessions({})
    return {"status": "success", "message": "All sessions cleared"}
