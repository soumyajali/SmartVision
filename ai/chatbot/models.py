from pydantic import BaseModel
from typing import List, Dict, Optional, Any

class SceneContext(BaseModel):
    detections: List[Dict[str, Any]] = []
    counts: Dict[str, int] = {}
    faces: List[Dict[str, Any]] = []
    ocr: List[Dict[str, Any]] = []
    timestamp: str = ""

class ChatQuery(BaseModel):
    query: str
    context: Optional[SceneContext] = None

class ChatResponse(BaseModel):
    response: str
    intent: str
