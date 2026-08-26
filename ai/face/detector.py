import mediapipe as mp
import cv2
import numpy as np

class FaceDetector:
    def __init__(self, min_detection_confidence=0.5):
        self.mp_face_detection = mp.solutions.face_detection
        self.detector = self.mp_face_detection.FaceDetection(
            model_selection=0, # 0 is for close-range faces (within 2m)
            min_detection_confidence=min_detection_confidence
        )

    def detect(self, image: np.ndarray):
        """
        Detects faces in an RGB image.
        Returns a list of bounding boxes: [{"x1": x1, "y1": y1, "x2": x2, "y2": y2, "confidence": conf}]
        """
        results = self.detector.process(image)
        faces = []
        
        if not results.detections:
            return faces
            
        h, w, _ = image.shape
        
        for detection in results.detections:
            bboxC = detection.location_data.relative_bounding_box
            x1 = int(bboxC.xmin * w)
            y1 = int(bboxC.ymin * h)
            width = int(bboxC.width * w)
            height = int(bboxC.height * h)
            x2 = x1 + width
            y2 = y1 + height
            
            # Clamp coordinates to image boundaries
            x1 = max(0, x1)
            y1 = max(0, y1)
            x2 = min(w, x2)
            y2 = min(h, y2)
            
            # Reject invalid bounding boxes
            if x2 <= x1 or y2 <= y1:
                continue
                
            faces.append({
                "x1": x1,
                "y1": y1,
                "x2": x2,
                "y2": y2,
                "confidence": detection.score[0]
            })
            
        return faces

    def crop_faces(self, image: np.ndarray, faces: list):
        """
        Returns a list of cropped face images based on detected bounding boxes.
        """
        crops = []
        for face in faces:
            crop = image[face['y1']:face['y2'], face['x1']:face['x2']]
            if crop.size > 0:
                crops.append(crop)
        return crops
