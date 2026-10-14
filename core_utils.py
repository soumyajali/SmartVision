"""
Utility Modules for Smart Vision AI
Provides performance monitoring, OCR, QR scanning, AI assistant, and report generation
"""

import time
import random
import psutil
import cv2
import numpy as np
from PIL import Image
from typing import Any, Dict, List, Optional, Tuple
import easyocr
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
import csv
from datetime import datetime
import os


def get_person_appearance_descriptor(image_bgr: np.ndarray) -> Optional[Tuple[np.ndarray, ...]]:
    if image_bgr is None or image_bgr.size == 0:
        return None

    height, width = image_bgr.shape[:2]
    person_crop = image_bgr[
        int(height * 0.05):max(int(height * 0.95), 1),
        int(width * 0.1):max(int(width * 0.9), 1),
    ]
    if person_crop.size == 0:
        person_crop = image_bgr

    resized = cv2.resize(person_crop, (48, 96), interpolation=cv2.INTER_AREA)
    hsv = cv2.cvtColor(resized, cv2.COLOR_BGR2HSV)
    regions = [hsv, *np.array_split(hsv, 3, axis=0)]
    descriptors = []
    for region in regions:
        histogram = cv2.calcHist([region], [0, 1], None, [12, 8], [0, 180, 0, 256])
        cv2.normalize(histogram, histogram, norm_type=cv2.NORM_L1)
        descriptors.append(histogram)
    return tuple(descriptors)


def compare_person_appearance(
    reference: Optional[Tuple[np.ndarray, ...]],
    candidate: Optional[Tuple[np.ndarray, ...]],
) -> float:
    if reference is None or candidate is None or len(reference) != 4 or len(candidate) != 4:
        return 0.0

    global_similarity = 1.0 - float(
        cv2.compareHist(reference[0], candidate[0], cv2.HISTCMP_BHATTACHARYYA)
    )
    region_similarities = [
        max(
            1.0 - float(cv2.compareHist(reference_region, candidate_region, cv2.HISTCMP_BHATTACHARYYA))
            for candidate_region in candidate[1:]
        )
        for reference_region in reference[1:]
    ]
    score = 0.55 * global_similarity + 0.45 * float(np.mean(region_similarities))
    return max(0.0, min(1.0, score))


def face_landmarks_to_location(
    landmarks: Any,
    image_shape: Tuple[int, ...],
    padding: float = 0.2,
) -> Optional[Tuple[int, int, int, int]]:
    if len(image_shape) < 2 or image_shape[0] <= 0 or image_shape[1] <= 0 or padding < 0:
        return None

    try:
        xs = np.asarray([point.x for point in landmarks], dtype=np.float32)
        ys = np.asarray([point.y for point in landmarks], dtype=np.float32)
    except (AttributeError, TypeError, ValueError):
        points = np.asarray(landmarks, dtype=np.float32)
        if points.ndim != 2 or points.shape[0] == 0 or points.shape[1] < 2:
            return None
        xs, ys = points[:, 0], points[:, 1]

    if xs.size == 0 or ys.size == 0 or not np.all(np.isfinite(xs)) or not np.all(np.isfinite(ys)):
        return None

    height, width = image_shape[:2]
    left = float(np.min(xs)) * width
    right = float(np.max(xs)) * width
    top = float(np.min(ys)) * height
    bottom = float(np.max(ys)) * height
    box_width = right - left
    box_height = bottom - top
    if box_width <= 0 or box_height <= 0:
        return None

    left = max(0, int(left - box_width * padding))
    right = min(width, int(right + box_width * padding))
    top = max(0, int(top - box_height * padding))
    bottom = min(height, int(bottom + box_height * padding))
    if right - left < 10 or bottom - top < 10:
        return None
    return top, right, bottom, left


def select_best_person_match(matches: List[Dict[str, Any]]) -> Dict[str, Any]:
    face_matches = [match for match in matches if match.get("match_type") == "face"]
    if not face_matches:
        raise ValueError("At least one face match is required.")
    return max(face_matches, key=lambda match: match["sim"])


def scale_bbox(
    bbox: Tuple[float, float, float, float],
    source_shape: Tuple[int, ...],
    target_size: Tuple[int, int],
) -> Tuple[int, int, int, int]:
    source_height, source_width = source_shape[:2]
    target_width, target_height = target_size
    if source_width <= 0 or source_height <= 0:
        raise ValueError("Source image dimensions must be positive.")

    scale_x = target_width / source_width
    scale_y = target_height / source_height
    x1, y1, x2, y2 = bbox
    return (
        max(0, min(target_width, int(x1 * scale_x))),
        max(0, min(target_height, int(y1 * scale_y))),
        max(0, min(target_width, int(x2 * scale_x))),
        max(0, min(target_height, int(y2 * scale_y))),
    )


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
            self.reader = easyocr.Reader(['en'], gpu=False, download_enabled=False)
        except Exception as e:
            print(f"Warning: Could not initialize OCR reader: {e}")
            self.reader = None
    
    def extract_text(self, image: np.ndarray, min_confidence: float = 0.25, rotation_info: list = [90, 180, 270]) -> List[Dict[str, any]]:
        """
        Extract text from an image, sorted in natural reading order (top-to-bottom, left-to-right).
        Automatically handles any orientation (0°, 90°, 180°, 270°) using rotation_info.
        
        Args:
            image: Input image as numpy array (BGR format from OpenCV)
            min_confidence: Minimum confidence threshold to exclude noise
            rotation_info: List of rotation angles to check for auto-orientation
            
        Returns:
            List of dictionaries containing text, bounding box, and confidence
        """
        if self.reader is None or image is None or image.size == 0:
            return []
        
        try:
            # Convert BGR / BGRA to RGB for EasyOCR
            if len(image.shape) == 3 and image.shape[2] == 3:
                image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            elif len(image.shape) == 3 and image.shape[2] == 4:
                image_rgb = cv2.cvtColor(image, cv2.COLOR_BGRA2RGB)
            else:
                image_rgb = image
            
            results = self.reader.readtext(image_rgb, rotation_info=rotation_info)
            
            extracted = []
            for (bbox, text, confidence) in results:
                t = str(text).strip()
                if float(confidence) >= min_confidence and len(t) > 0:
                    extracted.append({
                        "text": t,
                        "bbox": bbox,
                        "confidence": float(confidence)
                    })
            
            if extracted:
                # Helper to find vertical and horizontal center
                def box_center(item):
                    pts = item["bbox"]
                    cx = sum(p[0] for p in pts) / len(pts)
                    cy = sum(p[1] for p in pts) / len(pts)
                    return (cy, cx)

                # Group into reading lines by vertical proximity
                extracted.sort(key=lambda item: box_center(item)[0])
                lines = []
                current_line = []
                last_y = None
                line_tol = 18
                for item in extracted:
                    cy, cx = box_center(item)
                    if last_y is None or abs(cy - last_y) < line_tol:
                        current_line.append(item)
                        last_y = cy
                    else:
                        current_line.sort(key=lambda it: box_center(it)[1])
                        lines.extend(current_line)
                        current_line = [item]
                        last_y = cy
                if current_line:
                    current_line.sort(key=lambda it: box_center(it)[1])
                    lines.extend(current_line)
                extracted = lines

            return extracted
        except Exception as e:
            print(f"Error during OCR: {e}")
            return []
    
    def extract_text_simple(self, image: np.ndarray, min_confidence: float = 0.25, rotation_info: list = [90, 180, 270]) -> str:
        """
        Extract text from an image formatted cleanly with line breaks.
        Supports multi-angle rotation awareness (0°, 90°, 180°, 270°).
        """
        results = self.extract_text(image, min_confidence=min_confidence, rotation_info=rotation_info)
        if not results:
            return ""
        
        lines = []
        curr_line = []
        last_y = None
        for r in results:
            pts = r["bbox"]
            cy = sum(p[1] for p in pts) / len(pts)
            if last_y is None or abs(cy - last_y) < 20:
                curr_line.append(r["text"])
                last_y = cy
            else:
                if curr_line:
                    lines.append(" ".join(curr_line))
                curr_line = [r["text"]]
                last_y = cy
        if curr_line:
            lines.append(" ".join(curr_line))
            
        return "\n".join(lines)


class QRBarcodeScanner:
    """
    Detects and decodes QR codes and barcodes from images.
    """
    
    def __init__(self):
        """Initialize the QR/barcode scanner."""
        try:
            from pyzbar import pyzbar
            self.pyzbar = pyzbar
        except Exception as exc:
            print(f"Warning: QR/barcode scanning unavailable: {exc}")
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
        "Knife": "⚠️ Knife detected. Exercise caution! Keep blade pointed away and handle with care.",
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
        
        oname = object_name.lower().strip()
        # Generative / Category-Aware dynamic resolution
        if oname in ["knife", "scissors", "fork", "dagger", "sword"]:
            return {
                "description": f"Sharp utensil/implement ({object_name}) detected in the workspace.",
                "uses": "Food preparation, precision cutting, or craftwork.",
                "safety": "High caution required. Keep fingers curled ('claw grip'), point edges down, and store safely.",
                "facts": "Knives are among humanity's oldest tools, dating back over 2.5 million years to the Oldowan era."
            }
        elif oname in ["tomato", "apple", "banana", "orange", "carrot", "broccoli", "pizza", "sandwich"]:
            return {
                "description": f"Fresh food ingredient or item ({object_name}).",
                "uses": "Culinary preparation, healthy snacking, nutritional consumption.",
                "safety": "Ensure food is fresh, washed, and handled with clean utensils and surfaces.",
                "facts": f"{object_name.capitalize()} contains essential vitamins and minerals supporting metabolic wellness."
            }
        elif oname in ["car", "bus", "truck", "motorcycle", "bicycle"]:
            return {
                "description": f"Vehicular transport unit ({object_name}).",
                "uses": "Personal or commercial transit, cargo conveyance, mobility.",
                "safety": "Maintain safe stopping distances, adhere to lane regulations, and observe traffic alerts.",
                "facts": f"Modern {object_name}s integrate autonomous sensors, telemetry, and advanced safety envelopes."
            }
        
        # Default info with intelligent formatting
        return {
            "description": f"{object_name.capitalize()} recognized by SmartVision neural visual perception.",
            "uses": "Identified in the active environment for tracking, contextual reasoning, and spatial awareness.",
            "safety": "Standard situational safety precautions recommended.",
            "facts": f"{object_name.capitalize()} is cataloged within the 80 canonical YOLOv8 classes and real-time open-vocabulary database."
        }
    
    def get_recommendation(self, object_name: str) -> str:
        """
        Get a smart recommendation for a detected object.
        """
        # Try exact match first
        if object_name in self.RECOMMENDATIONS:
            return self.RECOMMENDATIONS[object_name]
        
        # Try case-insensitive match
        for key, value in self.RECOMMENDATIONS.items():
            if key.lower() == object_name.lower():
                return value
        
        oname = object_name.lower().strip()
        if oname in ["knife", "scissors"]:
            return f"⚠️ {object_name.capitalize()} detected. Keep blade oriented away from fingers and place on a stable surface."
        elif oname in ["tomato", "apple", "orange", "food"]:
            return f"🥗 Fresh {object_name} detected. Great time for a healthy snack or fresh recipe preparation!"
        elif oname in ["car", "motorcycle", "bicycle"]:
            return f"🚗 Vehicle ({object_name}) in frame. Monitor proximity and maintain safe lane clearance."
        
        # Default recommendation
        return f"💡 {object_name.capitalize()} detected. Visual tracking and contextual analysis active."


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
    Advanced Multimodal Conversational Vision Agent that works like ChatGPT and Google Gemini.
    Powered by SmartVisionAssistant, supporting:
    - Google Gemini (Gemini 1.5 / 2.0 Flash)
    - OpenAI ChatGPT (GPT-4o / GPT-4o-mini)
    - SmartVision Neural AI (Built-in Zero-Key Generative Reasoning Engine)
    """
    
    def __init__(self, api_key: str = None, provider: str = "auto", gemini_key: str = None):
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY", "")
        self.gemini_key = gemini_key or os.environ.get("GEMINI_API_KEY", "")
        self.provider = provider
        from ai.chatbot.smart_assistant import SmartVisionAssistant
        self.assistant = SmartVisionAssistant()
        self.assistant.set_provider_and_keys(
            provider=self.provider,
            gemini_key=self.gemini_key,
            openai_key=self.api_key
        )
        self.history = self.assistant.history

    def set_provider_and_keys(self, provider: str, gemini_key: str = "", openai_key: str = ""):
        self.provider = provider
        if gemini_key is not None and gemini_key != "":
            self.gemini_key = gemini_key
        if openai_key is not None and openai_key != "":
            self.api_key = openai_key
        self.assistant.set_provider_and_keys(
            provider=self.provider,
            gemini_key=self.gemini_key,
            openai_key=self.api_key
        )

    def clear_history(self):
        self.assistant.clear_history()
        self.history = self.assistant.history

    def ask(self, question: str, context_detections: List[Dict], ocr_text: str = "") -> str:
        # Keep keys and provider synced
        self.assistant.set_provider_and_keys(
            provider=self.provider,
            gemini_key=self.gemini_key or os.environ.get("GEMINI_API_KEY", ""),
            openai_key=self.api_key or os.environ.get("OPENAI_API_KEY", "")
        )
        # The Streamlit UI switches this wrapper's history when changing chats.
        # Keep the underlying model on that same list so replies survive reruns.
        self.assistant.history = self.history
        response = self.assistant.ask(question, context_detections=context_detections, ocr_text=ocr_text)
        self.history = self.assistant.history
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
    Estimates metric distance based on calibrated pinhole camera model
    and known real-world physical object dimensions.
    """
    @staticmethod
    def estimate(bbox: List[int], img_height: int, calibration_factor: float = 1.0) -> float:
        # box format: [x1, y1, x2, y2]
        h = bbox[3] - bbox[1]
        if h <= 0: return 99.9
        relative_height = h / img_height
        distance = calibration_factor / (relative_height + 0.001)
        return round(distance, 1)

    @staticmethod
    def estimate_metric(label: str, bbox: List[float], img_width: int, img_height: int) -> Dict[str, Any]:
        """
        Calibrated metric distance estimation using known physical dimensions.
        bbox: [x1, y1, x2, y2] in pixels
        """
        from core.distance_estimation import default_distance_estimator
        norm_rect = {
            'left': float(bbox[0]) / max(1, img_width),
            'top': float(bbox[1]) / max(1, img_height),
            'right': float(bbox[2]) / max(1, img_width),
            'bottom': float(bbox[3]) / max(1, img_height),
        }
        return default_distance_estimator.estimate_distance(label, norm_rect)


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


# ---------------- MULTI-LINGUAL ROBUST TRANSLATION ----------------
TRANSLATION_LANG_MAP = {
    'hindi': ('hi', 'hi-IN'),
    'hi': ('hi', 'hi-IN'),
    'kannada': ('kn', 'kn-IN'),
    'kn': ('kn', 'kn-IN'),
    'telugu': ('te', 'te-IN'),
    'te': ('te', 'te-IN'),
    'tamil': ('ta', 'ta-IN'),
    'ta': ('ta', 'ta-IN'),
    'malayalam': ('ml', 'ml-IN'),
    'ml': ('ml', 'ml-IN'),
    'marathi': ('mr', 'mr-IN'),
    'mr': ('mr', 'mr-IN'),
    'bengali': ('bn', 'bn-IN'),
    'bn': ('bn', 'bn-IN'),
    'gujarati': ('gu', 'gu-IN'),
    'gu': ('gu', 'gu-IN'),
    'punjabi': ('pa', 'pa-IN'),
    'pa': ('pa', 'pa-IN'),
    'odia': ('or', 'or-IN'),
    'or': ('or', 'or-IN'),
    'urdu': ('ur', 'ur-PK'),
    'ur': ('ur', 'ur-PK'),
    'spanish': ('es', 'es-ES'),
    'es': ('es', 'es-ES'),
    'french': ('fr', 'fr-FR'),
    'fr': ('fr', 'fr-FR'),
    'german': ('de', 'de-DE'),
    'de': ('de', 'de-DE'),
    'chinese (simplified)': ('zh-CN', 'zh-CN'),
    'chinese': ('zh-CN', 'zh-CN'),
    'zh': ('zh-CN', 'zh-CN'),
    'japanese': ('ja', 'ja-JP'),
    'ja': ('ja', 'ja-JP'),
    'russian': ('ru', 'ru-RU'),
    'ru': ('ru', 'ru-RU'),
    'arabic': ('ar', 'ar-SA'),
    'ar': ('ar', 'ar-SA'),
    'english': ('en', 'en-US'),
    'en': ('en', 'en-US'),
}

def translate_robust(text: str, target_lang: str = 'hindi') -> str:
    """
    Robust multi-lingual translator with intelligent rate-limit handling,
    sentence chunking, and dual-provider fallback (MyMemory + Google).
    """
    if not text or not str(text).strip():
        return ""
        
    text = str(text).strip()
    key = target_lang.strip().lower()
    g_code, m_code = TRANSLATION_LANG_MAP.get(key, ('hi', 'hi-IN'))

    import re
    # Split into clean chunks of max 450 chars at line breaks
    lines = text.split('\n')
    chunks = []
    current = []
    curr_len = 0
    for line in lines:
        if curr_len + len(line) + 1 > 450 and current:
            chunks.append('\n'.join(current))
            current = [line]
            curr_len = len(line)
        else:
            current.append(line)
            curr_len += len(line) + 1
    if current:
        chunks.append('\n'.join(current))

    translated_chunks = []
    for chunk in chunks:
        # Don't translate MRZ lines or symbols-only lines
        if re.match(r'^[A-Z0-9<]{15,}$', chunk.strip()):
            translated_chunks.append(chunk)
            continue
            
        chunk_res = None
        # 1. Primary Provider: MyMemory
        try:
            from deep_translator import MyMemoryTranslator
            chunk_res = MyMemoryTranslator(source='en-US', target=m_code).translate(chunk)
        except Exception:
            pass

        # 2. Secondary Provider: Google
        if not chunk_res:
            try:
                from deep_translator import GoogleTranslator
                chunk_res = GoogleTranslator(source='auto', target=g_code).translate(chunk)
            except Exception:
                pass

        translated_chunks.append(chunk_res if chunk_res else chunk)

    return '\n'.join(translated_chunks)

