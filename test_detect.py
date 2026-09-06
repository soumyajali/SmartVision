from ultralytics import YOLO
import urllib.request
import cv2

urllib.request.urlretrieve("https://ultralytics.com/images/zidane.jpg", "zidane.jpg")
model = YOLO('SmartVision_v3.pt')
res = model('zidane.jpg')
print("Num detections:", len(res[0].boxes))
