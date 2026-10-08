import os
import cv2
import numpy as np

class FaceService:
    def __init__(self, faces_dir="known_faces"):
        self.faces_dir = faces_dir
        if not os.path.exists(self.faces_dir):
            os.makedirs(self.faces_dir)
            
        self.recognizer = cv2.face.LBPHFaceRecognizer_create()
        cascade_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'haarcascade_frontalface_default.xml')
        self.face_cascade = cv2.CascadeClassifier(cascade_path)
        self.label_map = {}
        self.is_trained = False
        
        # Temporal smoothing state
        self.recognition_history = {} # track_id -> list of predictions
        
        self.train_model()
        
    def train_model(self):
        faces = []
        labels = []
        self.label_map = {}
        current_label = 0
        
        # Look for images in the known_faces directory
        for filename in os.listdir(self.faces_dir):
            if filename.endswith(('.png', '.jpg', '.jpeg')):
                name = os.path.splitext(filename)[0].split('_')[0]
                filepath = os.path.join(self.faces_dir, filename)
                
                img = cv2.imread(filepath)
                if img is not None:
                    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                    detected_faces = self.face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
                    
                    if len(detected_faces) > 0:
                        (x, y, w, h) = detected_faces[0]
                        face_roi = gray[y:y+h, x:x+w]
                        
                        if name not in self.label_map.values():
                            self.label_map[current_label] = name
                            label_id = current_label
                            current_label += 1
                        else:
                            label_id = list(self.label_map.keys())[list(self.label_map.values()).index(name)]
                            
                        faces.append(face_roi)
                        labels.append(label_id)
                        
        if len(faces) > 0:
            self.recognizer.train(faces, np.array(labels))
            self.is_trained = True
        else:
            self.is_trained = False
            
    def register_face(self, name, image):
        """Register a new face and retrain"""
        # Count existing images for this name to avoid overwrite
        count = sum(1 for f in os.listdir(self.faces_dir) if f.startswith(name))
        filepath = os.path.join(self.faces_dir, f"{name}_{count}.jpg")
        
        cv2.imwrite(filepath, image)
        self.train_model()
        return filepath
        
    def recognize(self, frame, person_box=None, track_id=None, threshold=85, required_hits=3):
        """Attempt to recognize a face inside a person bounding box or full frame with temporal smoothing"""
        if not self.is_trained:
            return None
            
        if person_box is not None:
            x1, y1, x2, y2 = person_box
            h, w = frame.shape[:2]
            # Ensure coordinates are within image boundaries
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            person_roi = frame[y1:y2, x1:x2]
        else:
            person_roi = frame
        
        if person_roi is None or person_roi.size == 0:
            return None
            
        gray = cv2.cvtColor(person_roi, cv2.COLOR_BGR2GRAY)
        detected_faces = self.face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=3)
        
        # If no face detected inside person roi, try detecting on full frame if person_box was provided
        if len(detected_faces) == 0 and person_box is not None:
            full_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            detected_faces = self.face_cascade.detectMultiScale(full_gray, scaleFactor=1.1, minNeighbors=3)
            if len(detected_faces) > 0:
                gray = full_gray
        
        if len(detected_faces) > 0:
            # We'll take the largest face found
            detected_faces = sorted(detected_faces, key=lambda f: f[2]*f[3], reverse=True)
            (fx, fy, fw, fh) = detected_faces[0]
            face_roi = gray[fy:fy+fh, fx:fx+fw]
            
            try:
                label, confidence = self.recognizer.predict(face_roi)
                # Lower confidence is better in LBPH (distance metric)
                if confidence < threshold: 
                    predicted_name = self.label_map.get(label, None)
                    
                    if track_id is not None and predicted_name is not None:
                        # Temporal smoothing
                        history = self.recognition_history.get(track_id, [])
                        history.append(predicted_name)
                        
                        # Keep only recent history
                        if len(history) > required_hits * 2:
                            history.pop(0)
                        self.recognition_history[track_id] = history
                        
                        # Check if we have enough consistent hits
                        if history.count(predicted_name) >= required_hits:
                            return predicted_name
                        return None
                    else:
                        return predicted_name
            except Exception:
                pass
                
        return None

    def recognize_face_details(self, frame, threshold=85):
        """Recognize face and return detailed (name, confidence, bbox)"""
        if not self.is_trained or frame is None or frame.size == 0:
            return None, None, None
            
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY) if len(frame.shape) == 3 else frame
        detected_faces = self.face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=3)
        
        if len(detected_faces) == 0:
            # Try with looser parameters
            detected_faces = self.face_cascade.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=2)
            
        if len(detected_faces) > 0:
            detected_faces = sorted(detected_faces, key=lambda f: f[2]*f[3], reverse=True)
            (fx, fy, fw, fh) = detected_faces[0]
            face_roi = gray[fy:fy+fh, fx:fx+fw]
            
            try:
                label, confidence = self.recognizer.predict(face_roi)
                if confidence < threshold:
                    name = self.label_map.get(label, "Unknown")
                    return name, confidence, (fx, fy, fw, fh)
                else:
                    return f"Unknown (distance {confidence:.1f})", confidence, (fx, fy, fw, fh)
            except Exception as e:
                return None, None, None
                
        return None, None, None

