from ultralytics import YOLO
import cv2
import numpy as np

model = YOLO('yolov8n.pt')
# Create a dummy image with a square
img = np.zeros((480, 640, 3), dtype=np.uint8)
img[100:300, 100:300] = [255, 255, 255]

# Detect on regular
res1 = model(img, verbose=False)
print("Regular detections:", len(res1[0].boxes))

# Detect on flipped
img_flip = cv2.flip(img, 1)
res2 = model(img_flip, verbose=False)
print("Flipped detections:", len(res2[0].boxes))

# Detect on contiguous flipped
img_flip_contig = np.ascontiguousarray(img_flip)
res3 = model(img_flip_contig, verbose=False)
print("Flipped contig detections:", len(res3[0].boxes))
