import os
import json
import base64
import cv2
import numpy as np
import time
import subprocess
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import asyncio

app = FastAPI(title="SmartVision API")

# Setup CORS to allow Next.js frontend to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLO model
print("Loading YOLOv8 Model...")
model = YOLO("yolov8m.pt")
print("Model loaded successfully.")

@app.get("/")
def read_root():
    return {"status": "System Online", "model": "YOLOv8m"}

@app.websocket("/ws/detect")
async def websocket_detect(websocket: WebSocket):
    await websocket.accept()
    
    # Store analytics per session
    frames_processed = 0
    start_time = time.time()
    counts = {}
    last_siren_time = 0.0

    try:
        while True:
            # Receive frame from client (expected base64 encoded jpeg)
            data = await websocket.receive_text()
            frame_start = time.time()
            print(f"Received frame of length: {len(data)}", flush=True)
            
            # Decode image
            try:
                # Remove data:image/jpeg;base64, prefix if present
                if "," in data:
                    data = data.split(",")[1]
                
                img_bytes = base64.b64decode(data)
                np_arr = np.frombuffer(img_bytes, np.uint8)
                img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
                
                if img is None:
                    print("Failed to decode image from base64", flush=True)
                    continue
                    
                print("Running YOLO inference...", flush=True)
                # Run YOLO inference
                results = model.predict(img, conf=0.5, verbose=False)
                print(f"YOLO inference complete. Found: {len(results[0].boxes)}", flush=True)
                
                detections = []
                frame_height, frame_width = img.shape[:2]
                
                total_conf = 0
                has_harmful = False
                
                for r in results:
                    boxes = r.boxes
                    for box in boxes:
                        x1, y1, x2, y2 = box.xyxy[0].tolist()
                        conf = float(box.conf[0]) * 100
                        cls = int(box.cls[0])
                        label = model.names[cls].upper()
                        
                        if label in ['KNIFE', 'SCISSORS']:
                            has_harmful = True
                        
                        total_conf += conf
                        
                        # Normalize coordinates (0-1) for frontend 3D mapping
                        norm_x = (x1 + x2) / 2 / frame_width
                        norm_y = (y1 + y2) / 2 / frame_height
                        norm_w = (x2 - x1) / frame_width
                        norm_h = (y2 - y1) / frame_height
                        
                        detections.append({
                            "id": f"{label}_{time.time()}",
                            "label": label,
                            "confidence": conf,
                            "x": norm_x,
                            "y": norm_y,
                            "width": norm_w,
                            "height": norm_h
                        })
                        
                        counts[label] = counts.get(label, 0) + 1
                
                # Trigger ambulance siren on backend if harmful object is detected
                if has_harmful:
                    current_time = time.time()
                    if current_time - last_siren_time > 2.5:  # Throttle to avoid overlapping sounds
                        subprocess.Popen(["afplay", "siren.wav"])
                        last_siren_time = current_time
                        print("🚨 Backend Triggered Ambulance Siren! 🚨", flush=True)

                frames_processed += 1
                elapsed = time.time() - start_time
                fps = frames_processed / elapsed if elapsed > 0 else 0
                latency = (time.time() - frame_start) * 1000
                avg_conf = total_conf / len(detections) if len(detections) > 0 else 0
                
                # Send back results
                await websocket.send_json({
                    "detections": detections,
                    "analytics": {
                        "fps": fps,
                        "latency": latency,
                        "avgConfidence": avg_conf,
                        "totalFrames": frames_processed,
                        "counts": counts
                    }
                })
                print("Sent JSON response", flush=True)
                
            except Exception as e:
                import traceback
                print(f"Error processing frame: {e}", flush=True)
                traceback.print_exc()
                
    except WebSocketDisconnect:
        print("Client disconnected", flush=True)
