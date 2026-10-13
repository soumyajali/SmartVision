"""
Configuration module for Custom AI Chatbot Backend
"""

import os

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

class Settings:
    PROJECT_NAME: str = "Smart AI Chatbot"
    VERSION: str = "1.0.0"
    API_PREFIX: str = "/api"
    
    # Model Configuration
    BASE_MODEL_NAME: str = os.environ.get("BASE_MODEL_NAME", "Qwen/Qwen2.5-0.5B-Instruct")
    LORA_ADAPTER_DIR: str = os.path.join(BASE_DIR, "checkpoints", "qwen_chatbot_lora")
    DEVICE: str = os.environ.get("DEVICE", "cpu")  # 'cpu', 'mps', 'cuda'
    
    # Generation Defaults
    DEFAULT_TEMPERATURE: float = 0.7
    DEFAULT_MAX_NEW_TOKENS: int = 512
    DEFAULT_SYSTEM_PROMPT: str = (
        "You are an intelligent, friendly, and articulate AI assistant. "
        "Answer questions accurately, explain concepts step by step, and write clean, commented code."
    )
    
    # Storage Paths
    DATA_DIR: str = os.path.join(BASE_DIR, "backend", "data")
    SESSIONS_FILE: str = os.path.join(DATA_DIR, "sessions.json")
    RAG_DOCS_DIR: str = os.path.join(DATA_DIR, "rag_documents")
    RAG_INDEX_FILE: str = os.path.join(DATA_DIR, "rag_index.json")

settings = Settings()
os.makedirs(settings.DATA_DIR, exist_ok=True)
os.makedirs(settings.RAG_DOCS_DIR, exist_ok=True)
