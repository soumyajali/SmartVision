import tempfile
import cv2
import math
import numpy as np
import urllib.request
from ultralytics import YOLO

# Create a dummy video
out = cv2.VideoWriter('dummy.mp4', cv2.VideoWriter_fourcc(*'mp4v'), 10, (100,100))
for i in range(10):
    out.write(np.zeros((100,100,3), dtype=np.uint8))
out.release()

with open('dummy.mp4', 'rb') as f:
    video_bytes = f.read()

with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tfile:
    tfile.write(video_bytes)
    temp_path = tfile.name

cap = cv2.VideoCapture(temp_path)
print("cap is opened:", cap.isOpened())
if cap.isOpened():
    ret, frame = cap.read()
    print("Read frame:", ret)
cap.release()
