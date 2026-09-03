from ultralytics import YOLO
import cv2
import numpy as np
import pprint

model = YOLO("yolov8m.pt")
results = model.predict("test_image.png", conf=0.25, verbose=False)
for r in results:
    if r.boxes is not None:
        detected = []
        for box in r.boxes:
            class_id = int(box.cls[0])
            conf = float(box.conf[0])
            name = model.names[class_id]
            detected.append({'name': name, 'confidence': round(conf, 3)})
        pprint.pprint(detected)
