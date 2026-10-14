"""
Main FastAPI Application Entrypoint.
Initializes the LLM Engine, RAG Engine, REST API routers, and mounts the ChatGPT-style frontend.
"""

import os
import sys
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

# Ensure root paths in sys.path
app_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.abspath(os.path.join(app_dir, ".."))
project_root = os.path.abspath(os.path.join(backend_dir, ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from backend.app.config import settings
from backend.app.api.chat import router as chat_router
from backend.app.api.sessions import router as sessions_router
from backend.app.api.rag import router as rag_router
from backend.app.model.llm_engine import LLMEngine
from backend.app.services.rag_engine import RAGEngine

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Full-stack AI Chatbot powered by local open-source LLM, LoRA fine-tuning, and RAG document grounding."
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API Routers
app.include_router(chat_router, prefix=settings.API_PREFIX)
app.include_router(sessions_router, prefix=settings.API_PREFIX)
app.include_router(rag_router, prefix=settings.API_PREFIX)

@app.on_event("startup")
async def startup_event():
    print("=" * 60)
    print(f"🚀 Starting {settings.PROJECT_NAME} (v{settings.VERSION})")
    print("=" * 60)
    try:
        # Pre-initialize singletons
        _ = RAGEngine.get_instance()
        _ = LLMEngine.get_instance()
    except Exception as e:
        print(f"Startup warning: {e}")

@app.get("/api/health")
def health_check():
    """Health status with hardware, active model, and memory state."""
    llm = LLMEngine.get_instance()
    rag = RAGEngine.get_instance()
    info = llm.get_info()
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "model_engine": info,
        "rag_status": {
            "indexed_documents": len(rag.documents),
            "indexed_chunks": len(rag.chunks)
        }
    }

@app.post("/api/model/reload")
def reload_model_adapter():
    """Dynamically reloads LoRA adapter from checkpoints without server restart."""
    llm = LLMEngine.get_instance()
    success = llm.reload_lora_if_available()
    return {
        "status": "success" if success else "unchanged",
        "lora_active": llm.is_lora_loaded,
        "adapter_dir": llm.lora_dir
    }

# Mount static frontend
frontend_dir = os.path.join(project_root, "frontend")
if os.path.exists(frontend_dir):
    app.mount("/static", StaticFiles(directory=frontend_dir), name="static")

    @app.get("/")
    def serve_frontend_root():
        index_path = os.path.join(frontend_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        return {"message": "Frontend not found"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=8001, reload=False)
