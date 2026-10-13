"""
Chat API Router.
Provides non-streaming and Server-Sent Event (SSE) streaming endpoints with multi-turn support,
RAG retrieval augmentation, and generation performance telemetry.
"""

import json
import time
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from backend.app.config import settings
from backend.app.model.llm_engine import LLMEngine
from backend.app.services.rag_engine import RAGEngine
from backend.app.api.sessions import _read_sessions, _write_sessions

router = APIRouter(prefix="/chat", tags=["chat"])

class ChatMessage(BaseModel):
    role: str  # "user", "assistant", or "system"
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    session_id: Optional[str] = None
    system_prompt: Optional[str] = None
    temperature: Optional[float] = Field(default=0.7, ge=0.0, le=1.5)
    max_tokens: Optional[int] = Field(default=512, ge=16, le=2048)
    use_rag: Optional[bool] = False
    rag_top_k: Optional[int] = 3

@router.post("")
def chat_completion(payload: ChatRequest):
    """
    Standard non-streaming chat generation.
    Returns generated text, token count, latency, and source citations if RAG is enabled.
    """
    if not payload.messages:
        raise HTTPException(status_code=400, detail="Messages array cannot be empty")

    llm = LLMEngine.get_instance()
    rag = RAGEngine.get_instance()

    # Prepare messages
    msg_dicts = [{"role": m.role, "content": m.content} for m in payload.messages]
    last_user_msg = next((m["content"] for m in reversed(msg_dicts) if m["role"] == "user"), "")

    citations = []
    effective_system_prompt = payload.system_prompt or settings.DEFAULT_SYSTEM_PROMPT

    # RAG Context Augmentation if requested
    if payload.use_rag and last_user_msg:
        rag_context, citations = rag.build_augmented_context(last_user_msg, top_k=payload.rag_top_k or 3)
        if rag_context:
            effective_system_prompt = f"{effective_system_prompt}\n\n{rag_context}"

    # Generate response
    result = llm.generate(
        messages=msg_dicts,
        temperature=payload.temperature or 0.7,
        max_new_tokens=payload.max_tokens or 512,
        system_prompt=effective_system_prompt
    )

    assistant_text = result["response"]
    metrics = result["metrics"]

    # Persist in session if session_id is provided
    if payload.session_id:
        _persist_message(payload.session_id, "user", last_user_msg)
        _persist_message(
            payload.session_id,
            "assistant",
            assistant_text,
            metrics=metrics,
            citations=citations
        )

    return {
        "response": assistant_text,
        "metrics": metrics,
        "citations": citations,
        "session_id": payload.session_id
    }

@router.post("/stream")
def chat_stream(payload: ChatRequest):
    """
    Real-time Server-Sent Events (SSE) streaming chat endpoint.
    Streams tokens as they are emitted by the model, followed by a final completion event.
    """
    if not payload.messages:
        raise HTTPException(status_code=400, detail="Messages array cannot be empty")

    llm = LLMEngine.get_instance()
    rag = RAGEngine.get_instance()

    msg_dicts = [{"role": m.role, "content": m.content} for m in payload.messages]
    last_user_msg = next((m["content"] for m in reversed(msg_dicts) if m["role"] == "user"), "")

    citations = []
    effective_system_prompt = payload.system_prompt or settings.DEFAULT_SYSTEM_PROMPT

    # RAG Context Augmentation
    if payload.use_rag and last_user_msg:
        rag_context, citations = rag.build_augmented_context(last_user_msg, top_k=payload.rag_top_k or 3)
        if rag_context:
            effective_system_prompt = f"{effective_system_prompt}\n\n{rag_context}"

    def event_generator():
        # Yield citation event first if RAG found sources
        if citations:
            yield f"data: {json.dumps({'event': 'citations', 'citations': citations})}\n\n"

        full_assistant_reply = []
        final_metrics = {}

        for chunk in llm.generate_stream(
            messages=msg_dicts,
            temperature=payload.temperature or 0.7,
            max_new_tokens=payload.max_tokens or 512,
            system_prompt=effective_system_prompt
        ):
            if chunk["event"] == "delta":
                full_assistant_reply.append(chunk["delta"])
                yield f"data: {json.dumps({'event': 'delta', 'delta': chunk['delta']})}\n\n"
            elif chunk["event"] == "done":
                final_metrics = chunk.get("metrics", {})
                yield f"data: {json.dumps({'event': 'done', 'metrics': final_metrics, 'citations': citations})}\n\n"

        # Persist conversation
        if payload.session_id:
            complete_text = "".join(full_assistant_reply).strip()
            _persist_message(payload.session_id, "user", last_user_msg)
            _persist_message(
                payload.session_id,
                "assistant",
                complete_text,
                metrics=final_metrics,
                citations=citations
            )

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

def _persist_message(session_id: str, role: str, content: str, metrics: dict = None, citations: list = None):
    """Helper to append message to active session file."""
    try:
        data = _read_sessions()
        if session_id not in data:
            data[session_id] = {
                "session_id": session_id,
                "title": content[:30] + "..." if len(content) > 30 else content,
                "system_prompt": settings.DEFAULT_SYSTEM_PROMPT,
                "created_at": time.time(),
                "updated_at": time.time(),
                "messages": []
            }
        
        entry = {
            "role": role,
            "content": content,
            "timestamp": time.time()
        }
        if metrics:
            entry["metrics"] = metrics
        if citations:
            entry["citations"] = citations

        data[session_id]["messages"].append(entry)
        data[session_id]["updated_at"] = time.time()
        _write_sessions(data)
    except Exception as e:
        print(f"[Chat] Could not persist message to session {session_id}: {e}")
