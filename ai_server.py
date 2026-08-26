import os
import cv2
import numpy as np
import base64
from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from ultralytics import YOLO
import easyocr
import mediapipe as mp
import faiss

app = FastAPI(title="Smart Vision Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("Loading Models...")
# YOLOv8
yolo_model = YOLO('yolov8s-world.pt')
yolo_model.set_classes(["person", "coffee mug", "keyboard", "headphones", "glasses", "cell phone"])

# EasyOCR
ocr_reader = easyocr.Reader(['en'], gpu=False) # Switch to GPU if available

# MediaPipe Face Detection
# mp_face_detection = mp.solutions.face_detection
# face_detector = mp_face_detection.FaceDetection(model_selection=0, min_detection_confidence=0.5)
face_detector = None

# FAISS for Face Embeddings
embedding_dim = 128 # Depends on the embedding model used later. Placeholder for now.
faiss_index = faiss.IndexFlatL2(embedding_dim)
registered_faces = {} # Map FAISS index ID to name

print("Models ready!")

class ImageRequest(BaseModel):
    image: str # base64 encoded string

class ChatbotRequest(BaseModel):
    query: str
    context: dict

def decode_image(base64_str: str) -> np.ndarray:
    try:
        image_data = base64.b64decode(base64_str)
        np_arr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
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

        results = yolo_model(img, verbose=False)
        
        detections = []
        for r in results:
            boxes = r.boxes
            for box in boxes:
                x1, y1, x2, y2 = box.xyxyn[0].tolist()
                conf = float(box.conf[0])
                cls_id = int(box.cls[0])
                label = yolo_model.names[cls_id]
                
                detections.append({
                    'rect': {'left': x1, 'top': y1, 'right': x2, 'bottom': y2},
                    'label': label,
                    'confidence': conf
                })
                
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

        results = ocr_reader.readtext(img)
        
        text_detections = []
        for (bbox, text, prob) in results:
            # bbox is a list of 4 points: [[x1, y1], [x2, y1], [x2, y2], [x1, y2]]
            # convert to normalized coordinates if needed, or keep absolute
            text_detections.append({
                'text': text,
                'confidence': prob,
                'bbox': [[float(p[0]), float(p[1])] for p in bbox]
            })
            
        return {'texts': text_detections}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/face/register')
async def register_face(req: ImageRequest, name: str = Body(...)):
    # Placeholder for actual embedding extraction logic
    try:
        img = decode_image(req.image)
        # 1. Detect Face
        # 2. Extract Embedding
        # 3. Add to FAISS index
        return {"status": "success", "message": f"Registered {name}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/face/recognize')
async def recognize_face(req: ImageRequest):
    # Placeholder for actual recognition logic
    try:
        img = decode_image(req.image)
        # 1. Detect Face
        # 2. Extract Embedding
        # 3. Search FAISS index
        return {"recognitions": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post('/chatbot/query')
async def chatbot_query(req: ChatbotRequest):
    # Rule-based processing based on context for now
    query_lower = req.query.lower()
    
    if "how many" in query_lower and "person" in query_lower:
        # Check context
        return {"response": "I see some people."}
    
    return {"response": "I heard your query."}

if __name__ == '__main__':
    uvicorn.run(app, host="0.0.0.0", port=5000)
