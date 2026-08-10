from ultralytics import YOLO
import cv2
import numpy as np

model = YOLO("yolov8m.pt")
img = np.zeros((480, 640, 3), dtype=np.uint8)
results = model.predict(img, conf=0.5, verbose=False)
print("Prediction success:", len(results))
