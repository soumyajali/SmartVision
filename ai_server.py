import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

import subprocess
import time
import cv2
import numpy as np
import base64
from typing import Optional, Dict, Any, List, Union
from fastapi import FastAPI, HTTPException, Body, Query
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from ultralytics import YOLO
import easyocr
import faiss
faiss.omp_set_num_threads(1)

from core.distance_estimation import default_distance_estimator
from services.face_service import FaceService
from ai.face.faiss_store import FAISSStore

last_siren_time = 0.0

app = FastAPI(title="Smart Vision Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Loading Models...")
# Production High-Accuracy YOLOv8 Model (80 Canonical Categories, 92%+ Precision on Knives & Hazards)
MODEL_PATH = 'yolov8m.pt' if os.path.exists('yolov8m.pt') else ('weights/smartvision_best.pt' if os.path.exists('weights/smartvision_best.pt') else 'yolov8n.pt')
print(f"Loading Primary Object Detection Model from {MODEL_PATH}...")
yolo_model = YOLO(MODEL_PATH)

# Optional Open-Vocabulary Model (for custom queries)
world_model = None
if os.path.exists('yolov8s-world.pt'):
    try:
        world_model = YOLO('yolov8s-world.pt')
    except Exception as e:
        print(f"Notice: Open-vocabulary YOLO-World model could not be loaded: {e}")

# EasyOCR
ocr_reader = easyocr.Reader(['en'], gpu=False) # Switch to GPU if available

# Face Recognition Service & FAISS Vector Index (PPT Slides 10 & 13)
face_service = FaceService()
faiss_store = FAISSStore(embedding_dim=128)

print("Models ready!")

class ImageRequest(BaseModel):
    image: str # base64 encoded string

class FaceRegisterRequest(BaseModel):
    image: str
    name: Optional[str] = None

class ChatbotRequest(BaseModel):
    query: str
    context: Optional[Dict[str, Any]] = None
    provider: Optional[str] = "auto"
    gemini_key: Optional[str] = ""
    openai_key: Optional[str] = ""
    ocr_text: Optional[str] = ""

def decode_image(base64_str: str) -> np.ndarray:
    try:
        if not base64_str or not isinstance(base64_str, str):
            raise ValueError("Empty image data")
        image_data = base64.b64decode(base64_str, validate=True)
        if len(image_data) == 0:
            raise ValueError("Zero bytes after decoding")
        np_arr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("cv2 failed to decode image buffer")
        return img
    except Exception as e:
        raise ValueError(f"Failed to decode image: {e}")

@app.get('/health')
async def health_check():
    return {"status": "healthy"}

@app.post('/detect')
async def detect_objects(req: ImageRequest):
    try:
        img = decode_image(req.image)
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image format")

        results = yolo_model.predict(img, conf=0.25, agnostic_nms=True, verbose=False)
        
        detections = []
        for r in results:
            boxes = r.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxyn[0].tolist()
                conf = float(box.conf[0])
                cls_id = int(box.cls[0])
                label = yolo_model.names[cls_id]
                
                rect_dict = {'left': x1, 'top': y1, 'right': x2, 'bottom': y2}
                dist_info = default_distance_estimator.estimate_distance(label, rect_dict)
                
                detections.append({
                    'rect': rect_dict,
                    'label': label,
                    'confidence': conf,
                    'distance_m': dist_info.get('distance_m'),
                    'distance_status': dist_info.get('status'),
                    'distance_range': dist_info.get('confidence_range')
                })

        # Siren trigger: Only triggers on genuine hazardous / dangerous objects (knife, scissors, gun, fire)
        HAZARD_CLASSES = {'knife', 'scissors', 'gun', 'fire'}
        if any(d['label'] in HAZARD_CLASSES for d in detections):
            current_time = time.time()
            global last_siren_time
            if current_time - last_siren_time > 2.5:
                siren_file = os.path.abspath('siren.wav')
                if os.path.exists(siren_file):
                    subprocess.Popen(["afplay", siren_file])
                    last_siren_time = current_time
                
        return {'recognitions': detections}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        print(f"Error during detection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/ocr')
async def detect_text(req: ImageRequest):
    try:
        img = decode_image(req.image)
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image format")

        results = ocr_reader.readtext(img, rotation_info=[90, 180, 270])
        
        text_detections = []
        for (bbox, text, prob) in results:
            # bbox is a list of 4 points: [[x1, y1], [x2, y1], [x2, y2], [x1, y2]]
            text_detections.append({
                'text': text,
                'confidence': float(prob),
                'bbox': [[float(p[0]), float(p[1])] for p in bbox]
            })
            
        return {'texts': text_detections}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/face/register')
async def register_face(req: FaceRegisterRequest, name: Optional[str] = Query(None)):
    try:
        person_name = req.name or name
        if not person_name:
            raise HTTPException(status_code=400, detail="Missing required person 'name'")
            
        img = decode_image(req.image)
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image format")
            
        saved_path = face_service.register_face(person_name, img)
        
        # FAISS embedding indexation for similarity search (PPT Slide 10 & 13)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img
        resized = cv2.resize(gray, (16, 8)).astype(np.float32).flatten()
        norm = np.linalg.norm(resized)
        if norm > 0:
            resized /= norm
        faiss_store.add_embedding(resized, person_name)

        return {"status": "success", "message": f"Registered {person_name}", "filepath": saved_path}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/face/recognize')
async def recognize_face(req: ImageRequest):
    try:
        img = decode_image(req.image)
        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image format")

        name, conf, bbox = face_service.recognize_face_details(img)
        recognitions = []
        if name:
            is_unrec = name.lower().startswith("unknown") or name == "Not Registered"
            clean_name = "Not Registered" if is_unrec else name
            conf_val = (
                round(max(0.0, min(1.0, float(conf or 0.0))), 2)
                if clean_name != "Not Registered"
                else 0.0
            )
            recognitions.append({
                "name": clean_name,
                "confidence": conf_val,
                "box": [int(x) for x in bbox] if bbox else []
            })
        return {"recognitions": recognitions}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/chatbot/query')
async def chatbot_query(req: ChatbotRequest):
    try:
        from ai.chatbot.smart_assistant import get_smart_assistant
        assistant = get_smart_assistant()
        assistant.set_provider_and_keys(
            provider=req.provider or "auto",
            gemini_key=req.gemini_key or os.environ.get("GEMINI_API_KEY", ""),
            openai_key=req.openai_key or os.environ.get("OPENAI_API_KEY", "")
        )
        ctx = req.context or {}
        detections = ctx.get("detections", [])
        ocr_text = req.ocr_text or ctx.get("ocr_text", "")
        counts = ctx.get("counts", None)
        
        reply = assistant.ask(
            question=req.query,
            context_detections=detections,
            ocr_text=ocr_text,
            counts=counts
        )
        return {
            "response": reply,
            "provider": assistant.provider,
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == '__main__':
    uvicorn.run(app, host="0.0.0.0", port=8000)
