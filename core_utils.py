"""
Utility Modules for Smart Vision AI
Provides performance monitoring, OCR, QR scanning, AI assistant, and report generation
"""

import time
import psutil
import cv2
import numpy as np
from PIL import Image
from typing import Dict, List, Optional, Tuple
import easyocr
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
import csv
from datetime import datetime
import os


class PerformanceMonitor:
    """
    Monitors system performance metrics including FPS, CPU, memory, and inference time.
    """
    
    def __init__(self):
        """Initialize the performance monitor."""
        self.start_time = time.time()
        self.frame_count = 0
        self.inference_times = []
        self.last_update = time.time()
    
    def update_fps(self):
        """Update the frame count and calculate FPS."""
        self.frame_count += 1
        current_time = time.time()
        elapsed = current_time - self.last_update
        
        if elapsed >= 1.0:  # Update every second
            fps = self.frame_count / elapsed
            self.frame_count = 0
            self.last_update = current_time
            return fps
        return None
    
    def record_inference(self, duration: float):
        """
        Record an inference time measurement.
        
        Args:
            duration: Time taken for inference in seconds
        """
        self.inference_times.append(duration)
        # Keep only last 100 measurements
        if len(self.inference_times) > 100:
            self.inference_times.pop(0)
    
    def get_average_inference_time(self) -> float:
        """
        Get the average inference time.
        
        Returns:
            Average inference time in seconds
        """
        if not self.inference_times:
            return 0.0
        return sum(self.inference_times) / len(self.inference_times)
    
    def get_cpu_usage(self) -> float:
        """
        Get current CPU usage percentage.
        
        Returns:
            CPU usage as a percentage
        """
        return psutil.cpu_percent(interval=0.1)
    
    def get_memory_usage(self) -> Dict[str, float]:
        """
        Get current memory usage information.
        
        Returns:
            Dictionary with memory usage statistics
        """
        mem = psutil.virtual_memory()
        return {
            "used_gb": mem.used / (1024**3),
            "total_gb": mem.total / (1024**3),
            "percent": mem.percent
        }
    
    def get_stats(self) -> Dict[str, any]:
        """
        Get all performance statistics.
        
        Returns:
            Dictionary containing all performance metrics
        """
        fps = self.update_fps()
        memory = self.get_memory_usage()
        
        return {
            "fps": fps if fps else 0.0,
            "cpu_percent": self.get_cpu_usage(),
            "memory_used_gb": memory["used_gb"],
            "memory_total_gb": memory["total_gb"],
            "memory_percent": memory["percent"],
            "avg_inference_time": self.get_average_inference_time(),
            "uptime_seconds": time.time() - self.start_time
        }


class OCRReader:
    """
    Provides OCR functionality using EasyOCR to extract text from images.
    """
    
    def __init__(self):
        """Initialize the OCR reader with EasyOCR."""
        try:
            self.reader = easyocr.Reader(['en'], gpu=False)
        except Exception as e:
            print(f"Warning: Could not initialize OCR reader: {e}")
            self.reader = None
    
    def extract_text(self, image: np.ndarray) -> List[Dict[str, any]]:
        """
        Extract text from an image.
        
        Args:
            image: Input image as numpy array (BGR format from OpenCV)
            
        Returns:
            List of dictionaries containing text, bounding box, and confidence
        """
        if self.reader is None:
            return []
        
        try:
            # Convert BGR to RGB for EasyOCR
            if len(image.shape) == 3 and image.shape[2] == 3:
                image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            else:
                image_rgb = image
            
            results = self.reader.readtext(image_rgb)
            
            extracted = []
            for (bbox, text, confidence) in results:
                extracted.append({
                    "text": text,
                    "bbox": bbox,
                    "confidence": float(confidence)
                })
            
            return extracted
        except Exception as e:
            print(f"Error during OCR: {e}")
            return []
    
    def extract_text_simple(self, image: np.ndarray) -> str:
        """
        Extract text from an image and return as a single string.
        
        Args:
            image: Input image as numpy array
            
        Returns:
            Extracted text as a single string
        """
        results = self.extract_text(image)
        return " ".join([r["text"] for r in results])


class QRBarcodeScanner:
    """
    Detects and decodes QR codes and barcodes from images.
    """
    
    def __init__(self):
        """Initialize the QR/barcode scanner."""
        try:
            from pyzbar import pyzbar
            self.pyzbar = pyzbar
        except ImportError:
            print("Warning: pyzbar not installed. QR/barcode scanning disabled.")
            self.pyzbar = None
    
    def scan(self, image: np.ndarray) -> List[Dict[str, any]]:
        """
        Scan an image for QR codes and barcodes.
        
        Args:
            image: Input image as numpy array (BGR format from OpenCV)
            
        Returns:
            List of dictionaries containing type, data, and bounding box
        """
        if self.pyzbar is None:
            return []
        
        try:
            # Convert to grayscale for better detection
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            decoded_objects = self.pyzbar.decode(gray)
            
            results = []
            for obj in decoded_objects:
                results.append({
                    "type": obj.type,
                    "data": obj.data.decode('utf-8'),
                    "bbox": obj.rect
                })
            
            return results
        except Exception as e:
            print(f"Error during QR/barcode scanning: {e}")
            return []


class AIAssistant:
    """
    Provides AI assistant functionality with object information and smart recommendations.
    """
    
    # Object information database
    OBJECT_INFO = {
        "Person": {
            "description": "A human being detected in the scene.",
            "uses": "Social interaction, work, recreation, daily activities.",
            "safety": "Generally safe. Maintain appropriate social distance.",
            "facts": "Humans are the only species known to create and use complex tools."
        },
        "Bottle": {
            "description": "A container for liquids, typically made of plastic, glass, or metal.",
            "uses": "Storing and consuming beverages, water storage.",
            "safety": "Check if bottle is securely closed. Glass bottles can break.",
            "facts": "The average person uses about 167 plastic water bottles per year."
        },
        "Chair": {
            "description": "A piece of furniture designed for sitting.",
            "uses": "Seating for work, dining, relaxation.",
            "safety": "Check stability before sitting. Ensure weight capacity.",
            "facts": "The oldest known chair dates back to around 2700 BC in Egypt."
        },
        "Laptop": {
            "description": "A portable personal computer with a clamshell form factor.",
            "uses": "Work, entertainment, communication, computing tasks.",
            "safety": "Ensure proper ventilation. Avoid liquids near electronics.",
            "facts": "The first laptop was released in 1981 and weighed 24 pounds."
        },
        "Mouse": {
            "description": "A hand-held input device for computers.",
            "uses": "Pointing, clicking, navigating interfaces.",
            "safety": "Take breaks to prevent repetitive strain injury.",
            "facts": "The computer mouse was invented in 1964 by Douglas Engelbart."
        },
        "Bag": {
            "description": "A flexible container used for carrying items.",
            "uses": "Transporting personal items, shopping, storage.",
            "safety": "Keep bags secure to prevent theft. Check weight distribution.",
            "facts": "The average woman owns 7 handbags and uses 2 regularly."
        },
        "Phone": {
            "description": "A portable electronic device for communication.",
            "uses": "Calling, texting, internet access, apps.",
            "safety": "Use hands-free while driving. Protect personal data.",
            "facts": "The first smartphone was released in 1992 (IBM Simon)."
        },
        "Knife": {
            "description": "A cutting tool with a sharp blade.",
            "uses": "Food preparation, cutting various materials.",
            "safety": "DANGEROUS - Handle with extreme care. Keep away from children.",
            "facts": "Knives have been used by humans for over 2.5 million years."
        },
        "Scissors": {
            "description": "A cutting tool with two blades pivoted together.",
            "uses": "Cutting paper, fabric, hair, various materials.",
            "safety": "Handle with care. Point away from body when not in use.",
            "facts": "Scissors were invented around 1500 BC in ancient Egypt."
        },
        "Cat": {
            "description": "A small domesticated carnivorous mammal.",
            "uses": "Companionship, pest control.",
            "safety": "Generally safe. Approach calmly if unfamiliar.",
            "facts": "Cats spend 70% of their lives sleeping."
        },
        "Dog": {
            "description": "A domesticated carnivorous mammal.",
            "uses": "Companionship, security, hunting, assistance.",
            "safety": "Ask owner before approaching. Some dogs may be aggressive.",
            "facts": "A dog's sense of smell is 10,000 to 100,000 times more sensitive than humans."
        }
    }
    
    # Smart recommendations
    RECOMMENDATIONS = {
        "Laptop": "Laptop detected. Charger nearby?",
        "Bottle": "Water bottle detected. Stay hydrated!",
        "Chair": "Chair available for sitting.",
        "Person": "Person detected. Greeting opportunity?",
        "Phone": "Phone detected. Check for notifications.",
        "Bag": "Bag detected. Ensure belongings are secure.",
        "Knife": "Knife detected. Exercise caution!",
        "Scissors": "Scissors detected. Handle with care.",
        "Cup": "Cup detected. Beverage time?",
        "Book": "Book detected. Time for reading?"
    }
    
    def get_object_info(self, object_name: str) -> Dict[str, str]:
        """
        Get detailed information about an object.
        
        Args:
            object_name: Name of the object
            
        Returns:
            Dictionary with object information
        """
        # Try exact match first
        if object_name in self.OBJECT_INFO:
            return self.OBJECT_INFO[object_name]
        
        # Try case-insensitive match
        for key, value in self.OBJECT_INFO.items():
            if key.lower() == object_name.lower():
                return value
        
        # Default info if not found
        return {
            "description": f"{object_name} detected in the scene.",
            "uses": "Various applications depending on context.",
            "safety": "General safety precautions apply.",
            "facts": f"{object_name} is one of the many objects our AI can detect."
        }
    
    def get_recommendation(self, object_name: str) -> str:
        """
        Get a smart recommendation for a detected object.
        
        Args:
            object_name: Name of the detected object
            
        Returns:
            Recommendation string
        """
        # Try exact match first
        if object_name in self.RECOMMENDATIONS:
            return self.RECOMMENDATIONS[object_name]
        
        # Try case-insensitive match
        for key, value in self.RECOMMENDATIONS.items():
            if key.lower() == object_name.lower():
                return value
        
        # Default recommendation
        return f"{object_name} detected."


class ReportGenerator:
    """
    Generates PDF and CSV reports for detection data.
    """
    
    def __init__(self):
        """Initialize the report generator."""
        self.output_dir = "reports"
        os.makedirs(self.output_dir, exist_ok=True)
    
    def generate_csv(self, detections: List[Dict], filename: Optional[str] = None) -> str:
        """
        Generate a CSV report from detection data.
        
        Args:
            detections: List of detection dictionaries
            filename: Optional custom filename
            
        Returns:
            Path to the generated CSV file
        """
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"detection_report_{timestamp}.csv"
        
        filepath = os.path.join(self.output_dir, filename)
        
        with open(filepath, 'w', newline='', encoding='utf-8') as csvfile:
            if detections:
                fieldnames = detections[0].keys()
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(detections)
        
        return filepath
    
    def generate_pdf(self, detections: List[Dict], stats: Dict, 
                    filename: Optional[str] = None) -> str:
        """
        Generate a PDF report from detection data and statistics.
        
        Args:
            detections: List of detection dictionaries
            stats: Dictionary containing detection statistics
            filename: Optional custom filename
            
        Returns:
            Path to the generated PDF file
        """
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"detection_report_{timestamp}.pdf"
        
        filepath = os.path.join(self.output_dir, filename)
        
        doc = SimpleDocTemplate(filepath, pagesize=letter)
        styles = getSampleStyleSheet()
        story = []
        
        # Title
        title = Paragraph("Smart Vision AI - Detection Report", styles['Title'])
        story.append(title)
        story.append(Spacer(1, 12))
        
        # Timestamp
        timestamp_str = f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        story.append(Paragraph(timestamp_str, styles['Normal']))
        story.append(Spacer(1, 12))
        
        # Statistics Section
        story.append(Paragraph("Detection Statistics", styles['Heading2']))
        story.append(Spacer(1, 6))
        
        stats_data = [
            ["Metric", "Value"],
            ["Total Detections", str(stats.get('total_detections', 0))],
            ["Today's Detections", str(stats.get('today_detections', 0))],
            ["Most Detected Object", stats.get('most_detected_object', 'N/A')],
            ["Most Detected Count", str(stats.get('most_detected_count', 0))],
            ["Average Confidence", f"{stats.get('average_confidence', 0):.3f}"]
        ]
        
        stats_table = Table(stats_data, colWidths=[2.5*inch, 2.5*inch])
        stats_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        story.append(stats_table)
        story.append(Spacer(1, 12))
        
        # Detection History Section
        story.append(Paragraph("Detection History", styles['Heading2']))
        story.append(Spacer(1, 6))
        
        if detections:
            # Limit to first 50 detections for PDF
            display_detections = detections[:50]
            
            data = [["ID", "Object", "Confidence", "Date", "Time"]]
            for det in display_detections:
                data.append([
                    str(det.get('id', '')),
                    det.get('object_name', ''),
                    f"{det.get('confidence', 0):.3f}",
                    det.get('date', ''),
                    det.get('time', '')
                ])
            
            table = Table(data, colWidths=[0.5*inch, 1.5*inch, 1*inch, 1*inch, 1*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('FONTSIZE', (0, 1), (-1, -1), 8)
            ]))
            story.append(table)
        else:
            story.append(Paragraph("No detection records available.", styles['Normal']))
        
        doc.build(story)
        return filepath


class ImageQualityAnalyzer:
    """
    Analyzes image quality metrics such as blurriness and brightness.
    """
    
    @staticmethod
    def analyze(image: np.ndarray) -> Dict[str, any]:
        """
        Analyze the given image for blurriness and brightness.
        
        Args:
            image: Input image as numpy array (BGR format)
            
        Returns:
            Dictionary containing quality metrics and warnings.
        """
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Calculate blurriness using variance of Laplacian
        laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
        is_blurry = laplacian_var < 100.0  # Threshold for blurriness
        
        # Calculate brightness
        brightness = np.mean(gray)
        is_dark = brightness < 40.0
        is_bright = brightness > 210.0
        
        return {
            "blur_score": laplacian_var,
            "is_blurry": is_blurry,
            "brightness_score": brightness,
            "is_dark": is_dark,
            "is_bright": is_bright,
            "quality_warning": "Blurry image" if is_blurry else ("Too dark" if is_dark else ("Too bright" if is_bright else None))
        }


class SceneDescriber:
    """
    Generates a natural language description of the current scene based on detected objects.
    """
    
    @staticmethod
    def generate_description(detections: List[Dict]) -> str:
        """
        Generate a scene description from a list of detections.
        
        Args:
            detections: List of detection dictionaries (requires 'object_name' key)
            
        Returns:
            String description of the scene.
        """
        if not detections:
            return "The scene appears to be empty."
            
        object_counts = {}
        for det in detections:
            name = det.get('object_name', 'unknown').lower()
            object_counts[name] = object_counts.get(name, 0) + 1
            
        descriptions = []
        for obj, count in object_counts.items():
            if count == 1:
                descriptions.append(f"one {obj}")
            else:
                # Basic pluralization
                plural = f"{obj}es" if obj.endswith(('s', 'sh', 'ch', 'x', 'z')) else f"{obj}s"
                descriptions.append(f"{count} {plural}")
                
        if len(descriptions) == 1:
            scene_text = f"I can see {descriptions[0]} in the scene."
        elif len(descriptions) == 2:
            scene_text = f"The scene contains {descriptions[0]} and {descriptions[1]}."
        else:
            scene_text = f"In this scene, I see {', '.join(descriptions[:-1])}, and {descriptions[-1]}."
            
        return scene_text


class VisionChatbot:
    """
    A rule-based conversational agent that can answer questions about the current scene's context.
    """
    
    def __init__(self):
        self.history = []
        
    def ask(self, question: str, context_detections: List[Dict]) -> str:
        """
        Answer a question based on current detection context.
        
        Args:
            question: User's question
            context_detections: Current frame's detections
            
        Returns:
            Chatbot response string
        """
        q_lower = question.lower()
        self.history.append({"role": "user", "content": question})
        
        object_counts = {}
        for det in context_detections:
            name = det.get('object_name', 'unknown').lower()
            object_counts[name] = object_counts.get(name, 0) + 1
            
        response = ""
        
        # Rule-based processing
        if "how many" in q_lower:
            found = False
            for obj, count in object_counts.items():
                if obj in q_lower:
                    response = f"I see {count} {obj}{'s' if count > 1 else ''}."
                    found = True
                    break
            if not found:
                response = "I don't see any of those right now."
                
        elif "what do you see" in q_lower or "describe" in q_lower:
            response = SceneDescriber.generate_description(context_detections)
            
        elif "where is" in q_lower:
            # Simple spatial inference if bounding boxes exist
            target = q_lower.replace("where is the ", "").replace("where is a ", "").replace("where is ", "").strip()
            target = target.rstrip("?")
            
            locations = []
            for det in context_detections:
                if det.get('object_name', '').lower() == target and 'bbox' in det:
                    # Bbox is typically [x1, y1, x2, y2]
                    box = det['bbox']
                    # Simplified positioning (requires image dimensions for true relative pos, assuming center roughly)
                    if len(box) >= 4:
                        x_center = (box[0] + box[2]) / 2
                        if x_center < 320: # Assuming 640 width
                            locations.append("on the left side")
                        else:
                            locations.append("on the right side")
            
            if locations:
                response = f"The {target} is {locations[0]}."
            else:
                response = f"I cannot locate the {target} in the current view."
                
        elif "danger" in q_lower or "safe" in q_lower:
            dangerous_objects = ["knife", "scissors", "gun", "fire", "gas cylinder"]
            detected_danger = [obj for obj in object_counts.keys() if obj in dangerous_objects]
            
            if detected_danger:
                response = f"Warning! I detect potentially dangerous objects: {', '.join(detected_danger)}."
            else:
                response = "The scene appears safe. No dangerous objects detected."
                
        else:
            response = "I'm a simple vision assistant. You can ask me 'what do you see?', 'how many [objects] are there?', or 'where is the [object]?'"
            
        self.history.append({"role": "assistant", "content": response})
        return response


class AdaptiveEngine:
    """
    Monitors processing time (FPS) and dynamically scales image resolution 
    if performance drops below thresholds.
    """
    def __init__(self, target_fps: int = 15):
        self.target_fps = target_fps
        self.current_scale = 1.0
        self.history = []
        
    def adapt(self, img: np.ndarray, processing_time: float) -> np.ndarray:
        current_fps = 1.0 / (processing_time + 0.001)
        self.history.append(current_fps)
        if len(self.history) > 10:
            self.history.pop(0)
            
        avg_fps = sum(self.history) / len(self.history)
        
        # Scale down if FPS is too low, scale back up if plenty of headroom
        if avg_fps < self.target_fps * 0.8 and self.current_scale > 0.4:
            self.current_scale -= 0.1
            self.history.clear()  # reset to avoid bouncing
        elif avg_fps > self.target_fps * 1.2 and self.current_scale < 1.0:
            self.current_scale += 0.1
            self.history.clear()
            
        if self.current_scale < 1.0:
            h, w = img.shape[:2]
            new_h, new_w = int(h * self.current_scale), int(w * self.current_scale)
            return cv2.resize(img, (new_w, new_h))
        return img


class LowLightEnhancer:
    """
    Enhances images detected as 'low light' using CLAHE.
    """
    @staticmethod
    def enhance(img: np.ndarray) -> np.ndarray:
        # Convert to LAB color space
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l_channel, a, b = cv2.split(lab)
        
        # Apply CLAHE to L channel
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        cl = clahe.apply(l_channel)
        
        # Merge back and convert to BGR
        limg = cv2.merge((cl, a, b))
        return cv2.cvtColor(limg, cv2.COLOR_LAB2BGR)


class DistanceEstimator:
    """
    Estimates distance based on bounding box height relative to image height.
    Assumes standard camera focal length projection approximation.
    """
    @staticmethod
    def estimate(bbox: List[int], img_height: int) -> float:
        # box format: [x1, y1, x2, y2]
        h = bbox[3] - bbox[1]
        
        # Avoid division by zero
        if h <= 0: return 99.9
        
        # Mock formula: distance is inversely proportional to relative height
        # A person taking up full frame is ~1m away. 
        relative_height = h / img_height
        
        # Base constant chosen for approximation (Focal Length * Real Height)
        distance = 1.0 / (relative_height + 0.001)
        return round(distance, 1)


class UnknownObjectDetector:
    """
    Flags tracked objects with consistently low confidence as 'Unknown'.
    """
    def __init__(self, confidence_threshold: float = 0.4):
        self.threshold = confidence_threshold
        self.unknown_track_ids = set()
        
    def detect(self, detections: List[Dict]) -> List[Dict]:
        for det in detections:
            conf = det.get('confidence', 1.0)
            
            if conf < self.threshold:
                # Mark it as unknown
                det['object_name'] = 'Unknown Object'
                det['confidence'] = conf
                
                if 'id' in det:
                    self.unknown_track_ids.add(det['id'])
            elif 'id' in det and det['id'] in self.unknown_track_ids:
                # If it was previously unknown but now has high conf, unflag it
                if conf >= self.threshold + 0.1:
                    self.unknown_track_ids.remove(det['id'])
                else:
                    det['object_name'] = 'Unknown Object'
                    
        return detections
